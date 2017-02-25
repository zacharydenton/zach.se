--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative
import Text.Pandoc.Options
import System.FilePath
import Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    match "static/**" $ do
        route   setRoot
        compile copyFileCompiler

    -- Tell hakyll to watch the less files
    match "assets/less/**.less" $ compile getResourceBody

    -- Compile the main less file
    -- We tell hakyll it depends on all the less files,
    -- so it will recompile it when needed
    d <- makePatternDependency "assets/less/**.less"
    rulesExtraDependencies [d] $ create ["css/main.css"] $ do
        route idRoute
        compile $ loadBody "assets/less/main.less"
            >>= makeItem
            >>= withItemBody 
                (unixFilter "lessc" ["--clean-css=--s0", "--include-path=assets/less", "-"])

    match "assets/**.coffee" $ do
        route $ setRoot `composeRoutes` setExtension "js"
        compile $ getResourceString
            >>= withItemBody
                (unixFilter "coffee" ["--stdio", "--compile"])
            >>= withItemBody
                (unixFilter "uglifyjs" ["--compress", "--mangle", "-"])

    match "pages/**" $ do
        route   $ setRoot `composeRoutes` cleanURL
        compile $ compiler
            >>= loadAndApplyTemplate "templates/page.html" pageCtx
            >>= loadAndApplyTemplate "templates/default.html" pageCtx
            >>= relativizeUrls

    categories <- buildCategories allPostsPattern (fromCapture "categories/*.html")

    match allPostsPattern $ do
        route $ postRoute `composeRoutes` cleanURL
        compile $ compiler
            >>= loadAndApplyTemplate "templates/post.html" postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archives.html"] $ do
        route cleanURL
        compile $ do
            posts <- recentFirst =<< loadAll postPattern
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives" `mappend`
                    constField "excerpt" "All posts by Zach Denton." `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    create ["travel.html"] $ do
        route cleanURL
        compile $ do
            posts <- recentFirst =<< loadAll "posts/travel/*"
            let travelCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Travel" `mappend`
                    constField "excerpt" "Travel stories and photos." `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" travelCtx
                >>= loadAndApplyTemplate "templates/default.html" travelCtx
                >>= relativizeUrls


    create ["index.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll postPattern
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "notitle" "yes" `mappend`
                    constField "bodyclass" "front" `mappend`
                    constField "excerpt" "On life, the universe, and everything." `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    -- Render RSS feed
    create ["rss.xml"] $ do
        route idRoute
        compile $
            loadAll postPattern
                >>= fmap (take 10) . recentFirst
                >>= renderAtom feedConfiguration feedCtx

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
compiler :: Compiler (Item String)
compiler = pandocCompilerWith defaultHakyllReaderOptions writerOptions where
  writerOptions = defaultHakyllWriterOptions {
    writerHTMLMathMethod = KaTeX "" "",
    writerHtml5 = True
  }

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    field "url" (fmap (maybe empty (dropFileName . toUrl)) . getRoute . itemIdentifier) `mappend`
    boolField "comments" (const True) `mappend`
    defaultContext

pageCtx :: Context String
pageCtx =
    boolField "comments" (const False) `mappend`
    defaultContext

feedCtx :: Context String
feedCtx =
    bodyField "description" `mappend`
    postCtx

renderKaTeX :: Item String -> Compiler (Item String)
renderKaTeX = withItemBody (unixFilter "bin/katex.js" [])

postRoute :: Routes
postRoute = customRoute $ removeDate . basename

postPattern :: Pattern
postPattern = "posts/*"

allPostsPattern :: Pattern
allPostsPattern = "posts/**"

setRoot :: Routes
setRoot = customRoute stripTopDir

removeDate :: FilePath -> FilePath
removeDate = drop 11

stripTopDir :: Identifier -> FilePath
stripTopDir = joinPath . tail . splitPath . toFilePath

basename :: Identifier -> FilePath
basename = last . splitPath . toFilePath

cleanURL :: Routes
cleanURL = customRoute fileToDirectory

fileToDirectory :: Identifier -> FilePath
fileToDirectory = flip combine "index.html" . dropExtension . toFilePath

config :: Configuration
config = defaultConfiguration {
        deployCommand = "bin/deploy.sh"
    }

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration {
    feedTitle = "Zach Denton",
    feedDescription = "On life, the universe, and everything.",
    feedAuthorName = "Zach Denton",
    feedAuthorEmail = "z@chdenton.com",
    feedRoot = "https://zach.se"
}

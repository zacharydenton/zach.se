--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import           Data.Monoid (mappend)
import           Control.Applicative
import           Text.Pandoc.Options
import           System.FilePath
import           Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    match "static/**" $ do
        route   setRoot
        compile copyFileCompiler

    -- Tell hakyll to watch the less files
    match "assets/less/**.less" $ do
        compile getResourceBody

    -- Compile the main less file
    -- We tell hakyll it depends on all the less files,
    -- so it will recompile it when needed
    d <- makePatternDependency "assets/less/**.less"
    rulesExtraDependencies [d] $ create ["css/main.css"] $ do
        route idRoute
        compile $ loadBody "assets/less/main.less"
            >>= makeItem
            >>= withItemBody 
                (unixFilter "lessc" ["-","--include-path=assets/less","--yui-compress","-O2"])

    match "assets/**.coffee" $ do
        route $ setRoot `composeRoutes` setExtension "js"
        compile $ getResourceString
            >>= withItemBody
                (unixFilter "coffee" ["--stdio", "--compile"])

    match ("pages/**") $ do
        route   $ setRoot `composeRoutes` cleanURL
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/page.html" defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ postRoute `composeRoutes` cleanURL
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archives.html"] $ do
        route cleanURL
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    constField "excerpt" "All posts by Zach Denton." `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    create ["index.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    constField "excerpt" "On life, the universe, and everything." `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/index.html" indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    -- Render RSS feed
    create ["rss.xml"] $ do
        route idRoute
        compile $ do
            loadAll "posts/*"
                >>= fmap (take 10) . recentFirst
                >>= renderAtom feedConfiguration feedCtx

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
pandocWriterOptions :: WriterOptions
pandocWriterOptions = defaultHakyllWriterOptions { writerHTMLMathMethod = MathJax "" }

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    field "url" (fmap (maybe empty (dropFileName . toUrl)) . getRoute . itemIdentifier) `mappend`
    defaultContext

feedCtx :: Context String
feedCtx =
    bodyField "description" `mappend`
    postCtx

postRoute :: Routes
postRoute = customRoute $ drop 11 . stripTopDir

setRoot :: Routes
setRoot = customRoute stripTopDir

stripTopDir :: Identifier -> FilePath
stripTopDir = joinPath . tail . splitPath . toFilePath

cleanURL :: Routes
cleanURL = customRoute fileToDirectory

fileToDirectory :: Identifier -> FilePath
fileToDirectory = (flip combine) "index.html" . dropExtension . toFilePath

config :: Configuration
config = defaultConfiguration {
        deployCommand = "rsync -av _site/ _deploy/ && cd _deploy && git add -A && git commit -m 'update site' && git push origin master"
    }

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration {
    feedTitle = "Zach Denton",
    feedDescription = "On life, the universe, and everything.",
    feedAuthorName = "Zach Denton",
    feedAuthorEmail = "z@chdenton.com",
    feedRoot = "http://zacharydenton.com"
}

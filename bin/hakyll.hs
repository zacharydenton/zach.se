{-# LANGUAGE OverloadedStrings, Arrows #-}
module Main where

import Prelude hiding (id)
import Control.Category (id)
import Control.Arrow ((>>>), (***), arr)
import Control.Monad (liftM)
import Data.Monoid (mempty, mconcat)
import Data.List (isPrefixOf, isSuffixOf)
import Data.Time
import System.FilePath
import System.Locale
import Text.Pandoc
import Hakyll

main :: IO ()
main = do
    currentTime <- liftM (formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ") getCurrentTime
    hakyllWith config $ do
        match "templates/*" $ compile templateCompiler

        match "static/css/**" $ do
            route $ setRoot `composeRoutes` setExtension "css"
            compile sass

        match "static/js/**.coffee" $ do
            route $ setRoot `composeRoutes` setExtension "js"
            compile coffeescript

        match (predicate (\i -> matches "static/**" i && not (matches "static/css/**" i) && not (matches "static/js/**.coffee" i))) $ do
            route $ setRoot
            compile copyFileCompiler

        -- compile posts twice to avoid dependency cycle
        
        posts <- group "posts" $ match "posts/*" $ do
            route $ postRoute `composeRoutes` cleanURL
            compile $ postsCompiler
                >>> arr stripIndexLink

        match "posts/*" $ do
            route $ postRoute `composeRoutes` cleanURL
            compile $ postsCompiler
                >>> setFieldPageList (take 8 . recentFirst) "templates/postitem.html" "recentposts" posts
                >>> applyTemplateCompiler "templates/post.html"
                >>> applyTemplateCompiler "templates/default.html"

        match "pages/**" $ do
            route $ setRoot `composeRoutes` cleanURL
            compile $ metaCompiler
                >>> setFieldPageList (take 8 . recentFirst) "templates/postitem.html" "recentposts" posts
                >>> applyTemplateCompiler "templates/page.html"
                >>> applyTemplateCompiler "templates/default.html"

        match "archives.html" $ route cleanURL
        create "archives.html" $ constA mempty
            >>> arr (setField "title" "Archives")
            >>> arr (setField "bodyclass" "archives")
            >>> arr (setField "excerpt" "All posts on the site.")
            >>> setFieldPageList ((filter (\p -> (getField "year" p) == "2010")) . recentFirst) "templates/postitem.html" "posts2010" posts
            >>> setFieldPageList ((filter (\p -> (getField "year" p) == "2011")) . recentFirst) "templates/postitem.html" "posts2011" posts
            >>> setFieldPageList ((filter (\p -> (getField "year" p) == "2012")) . recentFirst) "templates/postitem.html" "posts2012" posts
            >>> applyTemplateCompiler "templates/archives.html"
            >>> applyTemplateCompiler "templates/default.html"

        match "index.html" $ route idRoute
        create "index.html" $ constA mempty
            >>> arr (setField "title" "Home")
            >>> arr (setField "bodyclass" "home")
            >>> arr (setField "excerpt" "On life, the universe, and everything.")
            >>> setFieldPageList (take 1 . recentFirst) "templates/raw.html" "latest" posts
            >>> setFieldPageList (take 8 . tail . recentFirst) "templates/postitem.html" "recentposts" posts
            >>> applyTemplateCompiler "templates/index.html"
            >>> applyTemplateCompiler "templates/default.html"

        match "sitemap.xml" $ route idRoute
        create "sitemap.xml" $ constA mempty
            >>> arr (setField "updated" currentTime)
            >>> setFieldPageList id "templates/postsitemap.xml" "posts" posts
            >>> setFieldPageList (map (arr stripIndexLink)) "templates/postsitemap.xml" "pages" "pages/**"
            >>> applyTemplateCompiler "templates/sitemap.xml"

        match "atom.xml" $ route idRoute
        create "atom.xml" $ requireAll_ posts >>> renderAtom feedConfiguration

        match "rss.xml" $ route idRoute
        create "rss.xml" $ requireAll_ posts >>> renderRss feedConfiguration

        match "templates/*" $ compile templateCompiler

-- compilers

defaultCompiler :: Compiler Resource (Page String)
defaultCompiler = pageCompilerWith
    defaultHakyllParserState
    defaultHakyllWriterOptions {
        writerHTMLMathMethod = MathJax ""
    }

metaCompiler :: Compiler Resource (Page String)
metaCompiler = defaultCompiler
    >>> arr (trySetField "excerpt" "")
    >>> arr (trySetField "bodyclass" "")
    >>> arr (setField "root" "http://zacharydenton.com")
    >>> renderModificationTime "updated" "%Y-%m-%dT%H:%M:%SZ"
    >>> arr (copyBodyToField "description")

postsCompiler :: Compiler Resource (Page String)
postsCompiler = metaCompiler
    >>> arr (renderDateField "published" "%Y-%m-%d" "Unknown")
    >>> arr (renderDateField "date" "%b %e %Y" "Unknown")
    >>> arr (renderDateField "year" "%Y" "Unknown")

sass :: Compiler Resource String
sass = getResourceString
    >>> unixFilter "sass" ["-s", "--scss"]
    >>> arr compressCss

coffeescript :: Compiler Resource String
coffeescript = getResourceString
    >>> unixFilter "coffee" ["-sc"]

-- routes

postRoute :: Routes
postRoute = customRoute $ drop 11 . stripTopDir

setRoot :: Routes
setRoot = customRoute stripTopDir

stripTopDir :: Identifier a -> FilePath
stripTopDir = joinPath . tail . splitPath . toFilePath

cleanURL :: Routes
cleanURL = customRoute fileToDirectory

fileToDirectory :: Identifier a -> FilePath
fileToDirectory = (flip combine) "index.html" . dropExtension . toFilePath

-- miscellaneous functions

stripIndexLink :: Page a -> Page a
stripIndexLink = changeField "url" dropFileName

config :: HakyllConfiguration
config = defaultHakyllConfiguration {
        deployCommand = "rsync -av _site/ zach@helios.1337.cx:/srv/http/zacharydenton.com/public/",
        ignoreFile = ignoreFile'
    }
    where
        ignoreFile' path
            | "~" `isSuffixOf` fileName = True
            | ".swp" `isSuffixOf` fileName = True
            | otherwise = False
            where
                fileName = takeFileName path

pandocConfiguration :: WriterOptions
pandocConfiguration = defaultHakyllWriterOptions {
    writerHTMLMathMethod = MathML Nothing
}

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration {
    feedTitle = "Zach Denton",
    feedDescription = "On life, the universe, and everything.",
    feedAuthorName = "Zach Denton",
    feedAuthorEmail = "z@chdenton.com",
    feedRoot = "http://zacharydenton.com"
}

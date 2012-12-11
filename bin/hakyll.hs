{-# LANGUAGE OverloadedStrings, Arrows #-}
module Main where

import Prelude hiding (id)
import Control.Category (id)
import Control.Arrow ((>>>), (***), arr)
import Data.Monoid (mempty, mconcat)
import Data.List (isPrefixOf, isSuffixOf)
import System.FilePath
import Text.Pandoc
import Hakyll

main :: IO ()
main = hakyllWith config $ do
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
        compile $ pageCompiler
            >>> arr (renderDateField "fulldate" "%Y-%m-%d" "Unknown")
            >>> arr (renderDateField "date" "%b %e %Y" "Unknown")
            >>> arr (renderDateField "year" "%Y" "Unknown")
            >>> arr stripIndexLink

    _ <- match "posts/*" $ do
        route $ postRoute `composeRoutes` cleanURL
        compile $ nicePageCompiler
            >>> renderModificationTime "updated" "%Y-%m-%d"
            >>> arr (renderDateField "fulldate" "%Y-%m-%d" "Unknown")
            >>> arr (renderDateField "date" "%b %e %Y" "Unknown")
            >>> arr (copyBodyToField "description")
            >>> setFieldPageList (take 8 . recentFirst) "templates/postitem.html" "recentposts" posts
            >>> applyTemplateCompiler "templates/post.html"
            >>> applyTemplateCompiler "templates/default.html"

    match "pages/**" $ do
        route $ setRoot `composeRoutes` cleanURL
        compile $ nicePageCompiler
            >>> renderModificationTime "updated" "%Y-%m-%d"
            >>> setFieldPageList (take 8 . recentFirst) "templates/postitem.html" "recentposts" posts
            >>> applyTemplateCompiler "templates/page.html"
            >>> applyTemplateCompiler "templates/default.html"

    match "archives.html" $ route cleanURL
    create "archives.html" $ constA mempty
        >>> arr (setField "title" "Archives")
        >>> arr (setField "bodyclass" "archives")
        >>> setFieldPageList (take 8 . recentFirst) "templates/postitem.html" "recentposts" posts
        >>> setFieldPageList ((filter (\p -> (getField "year" p) == "2010")) . recentFirst) "templates/postitem.html" "posts2010" posts
        >>> setFieldPageList ((filter (\p -> (getField "year" p) == "2011")) . recentFirst) "templates/postitem.html" "posts2011" posts
        >>> setFieldPageList ((filter (\p -> (getField "year" p) == "2012")) . recentFirst) "templates/postitem.html" "posts2012" posts
        >>> applyTemplateCompiler "templates/archives.html"
        >>> applyTemplateCompiler "templates/default.html"

    match "index.html" $ route idRoute
    create "index.html" $ constA mempty
        >>> arr (setField "title" "Zach Denton")
        >>> setFieldPageList (take 1 . recentFirst) "templates/raw.html" "latest" posts
        >>> setFieldPageList (take 8 . tail . recentFirst) "templates/postitem.html" "recentposts" posts
        >>> applyTemplateCompiler "templates/index.html"
        >>> applyTemplateCompiler "templates/default.html"

    match "sitemap.xml" $ route idRoute
    create "sitemap.xml" $ constA mempty
        >>> requireAllA "posts/*" postListSitemap
        >>> requireAllA "pages/**" pageListSitemap
        >>> applyTemplateCompiler "templates/sitemap.xml"

    match "rss.xml" $ route idRoute
    create "rss.xml" $
        requireAll_ "posts/*"
            >>> renderRss feedConfiguration

    match "templates/*" $ compile templateCompiler

-- compilers

nicePageCompiler :: Compiler Resource (Page String)
nicePageCompiler = pageCompilerWith
    defaultHakyllParserState
    defaultHakyllWriterOptions {
        writerHTMLMathMethod = MathJax ""
    }

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

postList :: Compiler (Page String, [Page String]) (Page String)
postList = buildList "posts" "templates/postitem.html"

postListSitemap :: Compiler (Page String, [Page String]) (Page String)
postListSitemap = buildList "posts" "templates/postsitemap.xml"

pageListSitemap :: Compiler (Page String, [Page String]) (Page String)
pageListSitemap = buildList "pages" "templates/postsitemap.xml"

buildList :: String -> Identifier Template -> Compiler (Page String, [Page String]) (Page String)
buildList field template = setFieldA field $
    arr (reverse . chronological)
        >>> arr (map stripIndexLink)
        >>> require template (\p t -> map (applyTemplate t) p)
        >>> arr mconcat
        >>> arr pageBody

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

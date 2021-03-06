{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module DbEg where

import Steshaw ((|>))
import Database.HDBC
import Database.HDBC.Sqlite3
import Control.Monad
import Control.Monad.Trans
import Control.Monad.Reader

newtype ImplicitConnection a = ImplicitConnection {
  getImplicitConnection :: ReaderT Connection IO a
} deriving (Monad, MonadIO, MonadReader Connection)

connect :: IO Connection
connect = connectSqlite3 "test1.db"

withConnection :: (Connection -> IO a) -> IO a
withConnection f = do
  c <- connect
  result <- f c
  disconnect c
  return result

doPopulate c = do
    tables <- getTables c
    when (notElem "descs" tables) $ do
      run c "create table descs (id integer not null, desc varchar(200) not null)" []
      insert <- prepare c "insert into descs (id, desc) values (?, ?)"
      mapM (execute insert)
        [ [toSql (1::Integer), toSql "one"]
        , [toSql (2::Integer), toSql "two"]
        , [toSql (3::Integer), toSql "three"]
        , [toSql (4::Integer), toSql "four"]
        , [toSql (5::Integer), toSql "five"]
        , [toSql (6::Integer), toSql "six"]
        ]
      commit c

populate :: IO ()
populate = withConnection doPopulate

--

allSql = ("select * from descs", [])

descSql = ("select desc from descs", [])

searchSql s = ("select desc from descs where desc like ?", [s])

--

dumpAll = withConnection $ \c ->
  quickQuery' c `uncurry` allSql

dumpDesc = withConnection $ \c ->
  quickQuery' c `uncurry` descSql

search s = withConnection $ \c ->
  quickQuery' c `uncurry` (searchSql s)

--

dumpAllI :: ImplicitConnection [[SqlValue]]
dumpAllI = do
  c <- ask
  liftIO $ quickQuery' c `uncurry` allSql

dumpDescI :: ImplicitConnection [[SqlValue]]
dumpDescI = do
  c <- ask
  liftIO $ quickQuery' c `uncurry` descSql

searchI :: SqlValue -> ImplicitConnection [[SqlValue]]
searchI s = do 
  c <- ask
  liftIO $ quickQuery' c `uncurry` (searchSql s)

--

runImplicitConnection c a = runReaderT (getImplicitConnection a) c

runDumpAllI :: IO [[SqlValue]]
runDumpAllI = withConnection $ \c -> runImplicitConnection c dumpAllI

runDumpDescI :: IO [[SqlValue]]
runDumpDescI = withConnection $ \c -> runImplicitConnection c dumpDescI

runSearchI :: String -> IO [[SqlValue]]
runSearchI s = withConnection $ \c -> runImplicitConnection c (searchI (toSql s))

--

goDumpAll :: IO ()
goDumpAll = runDumpAllI >>= mapM_ print

goDumpDesc :: IO ()
goDumpDesc = runDumpDescI >>= mapM_ print

goSearch :: String -> IO ()
goSearch s = runSearchI s >>= mapM_ print

--

eg1 :: IO ()
eg1 = withConnection $ \c -> do
  doPopulate c
  runImplicitConnection c implicitAction

implicitAction :: ImplicitConnection ()
implicitAction = do
    all <- dumpAllI
    liftIO $ do
      mapM_ print all
      putStrLn "\ndesc:"
    descs <- dumpDescI
    liftIO $ mapM_ print descs
    forM_ ["foo", "two", "f%"] $ \s -> do
      searchResults <- searchI (toSql s)
      liftIO $ do
        putStrLn $ "\nsearch " ++ show s ++ ":"
        forM_ searchResults $ mapM_ print

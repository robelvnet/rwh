main :: IO ()
main = do
  putStrLn "What's your name?"
  name <- getLine
  putStrLn $ "Welcome " ++ name ++ "!"

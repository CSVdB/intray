{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Intray.Server.Handler.AdminDeleteAccountSpec
    ( spec
    ) where

import TestImport

import qualified Network.HTTP.Types as Http
import Servant.Client

import Intray.Client

import Intray.Client.Gen ()
import Intray.Data.Gen ()
import Intray.Server.TestUtils

spec :: Spec
spec =
    withIntrayServer $
    describe "AdminDeleteAccount" $ do
        it "forbids non-admin users from deleting a user" $ \cenv ->
            forAllValid $ \uid ->
                requiresAdmin cenv $ \token ->
                    clientAdminDeleteAccount token uid
        it "deletes an account correctly" $ \cenv ->
            withValidNewUser cenv $ \ut ->
                withAdmin cenv $ \token -> do
                    AccountInfo {..} <-
                        runClientOrError cenv $ clientGetAccountInfo ut
                    NoContent <-
                        runClientOrError cenv $
                        clientAdminDeleteAccount token accountInfoUUID
                    errOrAccountInfo <- runClient cenv $ clientGetAccountInfo ut
                    case errOrAccountInfo of
                        Left err ->
                            case err of
                                FailureResponse {} ->
                                    Http.statusCode (responseStatus err) `shouldBe`
                                    404
                                _ ->
                                    expectationFailure
                                        "Should have gotten the right error."
                        Right ai ->
                            expectationFailure $
                            unlines
                                [ "Should not have found account info, got this instead:"
                                , show ai
                                ]

/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

module website.app;

/**
 * website.app
 *
 * Main application instance for the website
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

import vibe.d;

/**
 * Main instance, state et all
 */
public final class Website
{
    /**
     * Construct a new Website instance
     */
    this()
    {
        settings = new HTTPServerSettings();
        settings.bindAddresses = ["localhost"];
        settings.disableDistHost = true;
        settings.port = 4040;
        settings.serverString = "serpentos/website";
        settings.useCompressionIfPossible = true;
        settings.sessionIdCookie = "serpentos/session_id";

        router = new URLRouter();

        /* All static assets */
        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = "/static";
        router.get("/static/*", serveStaticFiles("static", fileSettings));

        router.rebuild();
    }

    /**
     * Start the server
     */
    void start()
    {
        listener = listenHTTP(settings, router);
    }

    /**
     * Stop the server
     */
    void stop()
    {
        listener.stopListening();
    }

private:

    HTTPListener listener;
    HTTPServerSettings settings;
    HTTPFileServerSettings fileSettings;
    URLRouter router;
}

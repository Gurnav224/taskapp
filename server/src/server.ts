import { readFile } from "node:fs/promises";
import app from "./app.ts";
import pool from "./database/pool.ts";
import {env} from "./config/env.ts";

const STARTUP_QUERY_TIMEOUT_MS = 10_000;
const INITIAL_RETRY_DELAY_MS = 1_000;
const MAX_RETRY_DELAY_MS = 30_000;

async function initializeDatabase(schemaSql: string): Promise<void> {
    let timeout: ReturnType<typeof setTimeout> | undefined;

    try {
        await Promise.race([
            pool.query(schemaSql),
            new Promise<never>((_, reject) => {
                timeout = setTimeout(
                    () => reject(new Error(`Database initialization timed out after ${STARTUP_QUERY_TIMEOUT_MS}ms`)),
                    STARTUP_QUERY_TIMEOUT_MS,
                );
            }),
        ]);
    } finally {
        if (timeout) {
            clearTimeout(timeout);
        }
    }
}

async function waitForDatabase(schemaSql: string): Promise<void> {
    let retryDelay = INITIAL_RETRY_DELAY_MS;

    while (true) {
        try {
            await initializeDatabase(schemaSql);
            return;
        } catch (err) {
            console.error(`Database initialization failed; retrying in ${retryDelay}ms:`, err);
            await new Promise((resolve) => setTimeout(resolve, retryDelay));
            retryDelay = Math.min(retryDelay * 2, MAX_RETRY_DELAY_MS);
        }
    }
}

async function start():Promise<void>{
    const schemaSql = await readFile(new URL("../../db/init.sql", import.meta.url), "utf8");
    await waitForDatabase(schemaSql);
    console.log(`Database initialized successfully`);

    app.listen(env.PORT, () => {
        console.log(`Server is running on port http://localhost:${env.PORT}`);
    });

}

start().catch((err) => {
    console.error("Error starting the server:", err);
    process.exit(1);
});
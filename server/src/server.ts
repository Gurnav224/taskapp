import app from "./app.ts";
import pool from "./database/pool.ts";
import {env} from "./config/env.ts";


async function start():Promise<void>{
    await pool.query("SELECT 1");

    console.log(`Database connected successfully`);

    app.listen(env.PORT, () => {
        console.log(`Server is running on port http://localhost:${env.PORT}`);
    });

}

start().catch((err) => {
    console.error("Error starting the server:", err);
    process.exit(1);
});
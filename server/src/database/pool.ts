import pg from "pg";
import {} from "../config/env.ts";

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
});

export default pool;
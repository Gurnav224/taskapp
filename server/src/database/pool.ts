import pg from "pg";
import { env } from "../config/env.ts";

const pool = new pg.Pool({
  connectionString: env.DATABASE_URL,
  connectionTimeoutMillis: 5_000,
});

export default pool;
import express from "express";
import {type Request, type Response} from "express";
import cors from "cors";
import pool from "./database/pool.ts";


const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (_req: Request, res: Response) => {
  res.json({
    "status": "success",
    "message": "Server is running",
    "ip": _req.ip
  })
});


app.get("/health", async (_req: Request, res: Response) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).json({
      "status": "success",
      "message": "Server is healthy",
      "ip": _req.ip
    });
  } catch (err) {
    console.error("Health check database query failed:", err);
    res.status(503).json({
      "status": "error",
      "message": "Server is unhealthy",
      "ip": _req.ip
    });
  }
});

export default app;
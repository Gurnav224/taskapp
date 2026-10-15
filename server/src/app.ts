import express from "express";
import {type Request, type Response} from "express";
import cors from "cors";


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


app.get("/health", (_req: Request, res: Response) => {
  res.json({
    "status": "success",
    "message": "Server is healthy",
    "ip": _req.ip
  })
});

export default app;
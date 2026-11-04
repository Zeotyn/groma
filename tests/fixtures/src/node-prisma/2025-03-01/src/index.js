import express from "express";
import { PrismaClient } from "@prisma/client";

const app = express();
const prisma = new PrismaClient();

app.get("/users/:id/orders", async (req, res) => {
  const orders = await prisma.order.findMany({ where: { userId: Number(req.params.id) } });
  res.json(orders);
});

app.listen(3000);

import { NextResponse } from "next/server";
import { checkHealth } from "@/lib/server";

export async function GET() {
  const health = await checkHealth();

  if (health.status === "healthy") {
    return NextResponse.json(health);
  } else {
    return NextResponse.json(health, { status: 503 });
  }
}

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from diagram_kit import Diagram

out = sys.argv[1] if len(sys.argv) > 1 else "example.html"
d = Diagram("Shop Checkout", 1200, 760, subtitle="example system · shop platform · one region")

d.icon("lock", '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><rect x="9" y="18" width="22" height="16" rx="3" fill="#1d8a4a"/><path d="M14 18v-5a6 6 0 0 1 12 0v5" fill="none" stroke="#1d8a4a" stroke-width="3"/></svg>')

d.flow("order", "Order path", "Customer to payment.", "solid", [
    ["browser", "Customer checks out."], ["cdn", "Static assets and TLS."], ["waf", "Bot and injection rules."],
    ["api", "Validates the cart."], ["orders", "Creates the order."], ["db", "Writes the order row."], ["pay", "Charges the card."]])
d.flow("events", "Order events", "Orders fan out to analytics.", "dashed", [
    ["orders", "Publishes order.created."], ["queue", "Durable topic."], ["wh", "Not built: nightly load."], ["vendor", "Blocked: no export agreed."]])

d.boundary("users", None, 16, 16, 200, 728, "Customers", st="ext", dash="6 4")
d.item("browser", "users", 116, 110, "Web browser", "checkout.example.com", st="ext", lw=150, type="Client")
d.item("mobile", "users", 116, 260, "Mobile app", "iOS · Android", st="ext", lw=150, type="Client")

d.boundary("platform", None, 236, 16, 740, 728, "Shop platform", st="built", sub="production")
d.boundary("edge", "platform", 252, 52, 200, 300, "Edge", dash="5 3")
d.item("cdn", "edge", 352, 110, "cdn-edge", "TLS · cache 5 min", type="CDN",
       cfg=[["Origins", "checkout-api"], ["TLS", "1.2+"], ["Cache", "300 s static"]], by="infra/edge.tf")
d.item("waf", "edge", 352, 240, "waf-rules", "managed + 4 custom", icon="lock", type="WAF", by="infra/edge.tf")

d.boundary("svc", "platform", 468, 52, 492, 300, "Services", dash="5 3")
d.item("api", "svc", 510, 110, "checkout-api", "REST · 3 replicas", pos="right", lw=150, type="Service",
       cfg=[["Runtime", "Go 1.25"], ["Replicas", "3"]], by="services/checkout")
d.item("orders", "svc", 510, 200, "order-svc", "writes orders · emits events", pos="right", lw=150, type="Service", by="services/orders")
d.item("fraud", "svc", 760, 290, "fraud-check", "score before charge", st="todo", pos="right", lw=150, type="Service",
       next="Add a scoring call between order-svc and the payment provider.")
d.chip("rl", "svc", 740, 96, 180, "rate-limit 50 rps", type="Policy", by="services/checkout/limits.yaml")
d.chip("rb", "svc", 740, 136, 180, "retry budget", st="todo", type="Policy", next="Cap retries at 10% of traffic.")

d.boundary("data", "platform", 252, 372, 708, 220, "Data", dash="5 3")
d.item("cache", "data", 352, 450, "session-cache", "Redis · 2 GB", type="Cache")
d.item("db", "data", 510, 450, "orders-db", "Postgres 16 · HA", type="Database", cfg=[["Backups", "daily, 30 days"]])
d.item("queue", "data", 700, 450, "order-events", "topic · 7-day retention", type="Queue")
d.item("wh", "data", 880, 450, "warehouse", "nightly load", st="todo", type="Warehouse", next="Pick a warehouse and build the nightly job.")

d.boundary("ops", "platform", 252, 608, 708, 120, "Observability", dash="5 3")
d.item("logs", "ops", 290, 668, "log-pipeline", "all services · 30 days", pos="right", lw=200, type="Logging")
d.item("alerts", "ops", 600, 668, "pager-alerts", "SLO burn rate", st="todo", pos="right", lw=200, type="Alerting",
       next="Define SLOs for checkout-api first.")

d.boundary("outside", None, 996, 16, 188, 728, "Outside", dash="6 4", sub="internet")
d.cloud("pay", "outside", 1090, 200, "Payment provider", "card charges · allowed", type="External API")
d.cloud("vendor", "outside", 1090, 450, "Analytics vendor", "export · blocked today", type="External API")

d.arrow("order", [(144, 110), (322, 110)])
d.arrow("order", [(380, 110), (480, 110)])
d.arrow("order", [(510, 138), (510, 170)])
d.arrow("order", [(510, 228), (510, 420)])
d.arrow("order", [(510, 82), (510, 70), (1090, 70), (1090, 170)])
d.badge("order", 240, 110)
d.arrow("events", [(538, 450), (670, 450)])
d.arrow("events", [(728, 450), (850, 450)])
d.arrow("events", [(908, 450), (1060, 450)], blocked=True)
d.blocked_mark("events", 1030, 450)
d.badge("events", 610, 450)

for p in d.check():
    print("WARN", p)
print("wrote", out, d.render(out))

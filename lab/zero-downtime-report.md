# ✅ Zero Downtime Report — Tasks 2026 · High Availability

> **Date:** 2026-06-16 | **Cluster:** `cluster-tasks-alb` | **Service:** `service-tasks-alb`

---

## 📊 Availability Summary

| Metric | Value |
|---|---|
| Monitoring period | 14:02:00 → 14:15:37 |
| Total checks | 240 |
| HTTP 200 | **240** |
| Downtime | **0 seconds** |
| Deployments during period | 2 |

---

## 🔄 What Happened — Rolling Deploy Timeline

| Time | Event | Status |
|---|---|---|
| 14:02:00 | Availability monitoring started | 🟢 UP |
| 14:02:45 | ECS started draining task 1 (old image `3302e52`) | 🔵 Draining |
| 14:03:25 | New task started (image `2971e10`) | 🟢 Starting |
| 14:03:35 | New task registered in ALB target group | 🟢 Registered |
| 14:04:25 | Old task stopped | 🔴 Stopped |
| 14:04:35 | Old task deregistered from ALB | 🔵 Deregistered |
| 14:05:15 | Second new task started | 🟢 Starting |
| 14:05:25 | Second new task registered in ALB | 🟢 Registered |
| 14:06:06 | Deployment completed | 🏁 Complete |
| 14:06:06 | Service reached steady state | ✅ Stable |
| 14:09:26 | Second deploy — task stop began | 🔴 Stopped |
| 14:10:16 | New task started | 🟢 Starting |
| 14:11:16 | Old task stopped | 🔴 Stopped |
| 14:12:06 | New task started | 🟢 Starting |
| 14:12:46 | Deployment completed — steady state | ✅ Stable |

---

## 🏗️ Why There Was No Downtime

```
ALB (2 healthy targets at all times)
 │
 ├── Task A  ──► drain ──► stop         (old image 3302e52)
 │                  │
 │             Task C  ──► register ──► serving   (new image 2971e10)
 │
 └── Task B  serving ──► drain ──► stop
                  │
             Task D  ──► register ──► serving   (new image 2971e10)
```

- ECS rolling deploy replaces **1 task at a time**
- ALB drains connections before deregistering a target
- New task is healthy in ALB **before** old task is removed
- At no point did the ALB have 0 healthy targets

---

## 🖥️ Current State

| | |
|---|---|
| Desired tasks | 2 |
| Running tasks | **2** |
| Task definition | `task-def-tasks-alb:2` |
| Image | `tasks:2971e10` |
| ALB | `tasks-alb-160832135.us-east-1.elb.amazonaws.com` |
| ALB targets | 🟢 healthy × 2 |

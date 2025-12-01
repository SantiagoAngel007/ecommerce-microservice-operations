# Análisis de Costos de Infraestructura

**Versión:** 1.0  
**Fecha:** Diciembre 2025  
**Período de Análisis:** Mensual  
**Región:** us-central1 (Iowa, USA)

---

## Resumen Ejecutivo

La siguiente información la inferimos considerando la cantidad de créditos de Google cloud que hemos gastado durante el desarrollo de este proyecto:

### Costo Total Mensual

| Ambiente | Costo Mensual | Costo Anual |
|----------|---------------|-------------|
| **DEV** | $300.00 | $3000.00 |
| **STAGE** | $150.00 | $1,800.00 |
| **PROD** | $420.00 | $5,040.00 |


### Créditos GCP Free Trial

- **Créditos iniciales:** $300.00
- **Consumo mensual:** ~$630.00
- **Duración de créditos:** ~14 días (DEV+STAGE+PROD)
- **Duración solo DEV:** ~5 meses

**IMPORTANTE:** Los $300 de créditos se agotan rápidamente con los 3 ambientes activos.

---

## Costos por Ambiente

### DEV Environment

**Costo Total:** $850.00/mes

| Servicio | Especificaciones | Costo Mensual | % |
|----------|------------------|---------------|---|
| **GKE Autopilot** | 11 pods × 0.5 vCPU + 512Mi RAM | $35.00 | 58.3% |
| **Artifact Registry** | 5 GB almacenamiento + 10 GB egress | $5.00 | 8.3% |
| **VPC Networking** | Egress + NAT Gateway | $10.00 | 16.7% |
| **Cloud Logging** | 5 GB logs/mes | $5.00 | 8.3% |
| **Cloud Monitoring** | Métricas básicas | $3.00 | 5.0% |
| **Persistent Storage** | 10 GB SSD | $2.00 | 3.3% |

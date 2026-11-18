*&---------------------------------------------------------------------*
*& Include Z8FICR0100TOP                            - Report Z8FICR0100
*&---------------------------------------------------------------------*
REPORT Z8FICR0100.

TABLES: z8sd_billing_h, z8sd_quot_req, z8company_m. ", z8sd_quotation_h.

TABLES: sscrfields.

DATA ok_code TYPE sy-ucomm.

CONSTANTS gc_bukrs TYPE z8company_m-bukrs VALUE '1000'.

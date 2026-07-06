table 50112 "PLSR_Store Stock Buffer"
{
    Caption = 'Store Stock Buffer';
    TableType = Temporary; // กำหนดเป็น Temporary Table เพื่อทำงานบน Memory ทั้งหมด

    fields
    {
        field(1; "Item No."; Code[20]) { Caption = 'Item No.'; }
        field(2; "Variant Code"; Code[20]) { Caption = 'Variant Code'; }
        field(3; "Description"; Text[100]) { Caption = 'Description'; }
        field(4; "Base Unit of Measure"; Code[10]) { Caption = 'Base Unit of Measure'; }
        field(10; "ItemInventoryQty"; Decimal) { Caption = 'Inventory Qty'; }
        field(11; "ItemSoldTodayQty"; Decimal) { Caption = 'Sold Today Qty'; }
        field(12; "ItemSoldNotPostedQty"; Decimal) { Caption = 'Sold Not Posted Qty'; }
        field(13; "NetInventoryQty"; Decimal) { Caption = 'Net Inventory Qty'; }
    }

    keys
    {
        // กำหนด Composite PK เพื่อไม่ให้ Variant ชนกัน
        key(PK; "Item No.", "Variant Code")
        {
            Clustered = true;
        }
    }
}
query 50044 "MemberSalesHistory Q"
{

    Caption = 'MemberSalesHistory';
    QueryType = Normal;

    // ── FIX #1: OrderBy ──────────────────────────────────────────────────
    // เดิมของโค้ด optimize: ascending(Member_Account_No_, Store_No_, Date, Entry_No_, Line_No_)
    // ผิดจากต้นฉบับ เพราะ report ต้นฉบับ (76092) วนลูปแบบ nested:
    //   Member Contact  sorting("Account No.", "Contact No.")
    //     -> Member Sales Entry  sorting("Entry No.", "Line No.")  [link ผ่าน Contact No.]
    // แปลว่าลำดับจริงคือ: กลุ่มตาม Contact (เรียง Account No. -> Contact No. ก่อน)
    // แล้วภายในแต่ละ Contact ค่อยเรียงตาม Entry No. -> Line No.
    // แก้ให้ตรงกับต้นฉบับ:
    OrderBy = ascending(Account_No_, Member_Contact_No_, Entry_No_, Line_No_);

    // AVPWDLSVIP 14/07/2026 > Improve Performance of VIP Report(76092) - น้องปอ
    elements
    {
        dataitem(MemberSalesEntry; "LSC Member Sales Entry")
        {
            filter(DateFilter; Date) { }

            column(Entry_No_; "Entry No.") { }
            column(Line_No_; "Line No.") { }
            column(Member_Contact_No_; "Member Contact No.") { }
            column(Member_Account_No_; "Member Account No.") { }
            column(Store_No_; "Store No.") { }
            column(Document_No_; "Document No.") { }
            column(Date; Date) { }
            column(Transaction_No_; "Transaction No.") { }
            column(Item_No_; "Item No.") { }
            column(Description; Description) { }
            column(Item_Variant_Code; "Item Variant Code") { }
            column(Discount_Amount; "Discount Amount") { }

            // JOIN: LSC Member Contact — เพื่อให้ filter Search Name / Mobile / ID Card ได้
            // ใช้ InnerJoin เพราะต้องการเฉพาะ Sales Entry ที่มี Contact จริงๆ
            // (นี่คือ intent เดียวกับ PrintOnlyIfDetail = true ของต้นฉบับ)
            dataitem(MemberContact; "LSC Member Contact")
            {
                DataItemLink = "Contact No." = MemberSalesEntry."Member Contact No.";
                SqlJoinType = InnerJoin;

                // ── FIX #1 (ต่อ): เพิ่ม Account No. เพื่อใช้เป็น OrderBy หลัก ให้ตรงกับ
                // DataItemTableView = sorting("Account No.", "Contact No.") ของ Member Contact ต้นฉบับ
                column(Account_No_; "Account No.") { }

                // filter fields ตรงกับ RequestFilterFields ของ dummy dataitem ใน Report
                filter(SearchNameFilter; "Search Name") { }
                filter(MobilePhoneNoFilter; "Mobile Phone No.") { }
                filter(IDCardNoFilter; "PLSWS_ID Card No.") { }

                // JOIN: LSC Member Account — ดึง Description
                dataitem(MemberAccount; "LSC Member Account")
                {
                    DataItemLink = "No." = MemberSalesEntry."Member Account No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Member_Account_Description; Description) { }

                    // JOIN: LSC Transaction Header — ดึง Sale Is Return Sale
                    dataitem(TransactionHeader; "LSC Transaction Header")
                    {
                        DataItemLink =
                            "Transaction No." = MemberSalesEntry."Transaction No.",
                            "Store No." = MemberSalesEntry."Store No.",
                            "Receipt No." = MemberSalesEntry."Document No.";
                        SqlJoinType = LeftOuterJoin;

                        column(Sale_Is_Return_Sale; "Sale Is Return Sale") { }

                        // JOIN: LSC Trans. Sales Entry — ดึง UOM / QTY / Price
                        dataitem(TransSalesEntry; "LSC Trans. Sales Entry")
                        {
                            DataItemLink =
                                "Transaction No." = MemberSalesEntry."Transaction No.",
                                "Store No." = MemberSalesEntry."Store No.",
                                "Receipt No." = MemberSalesEntry."Document No.",
                                "Line No." = MemberSalesEntry."Line No.";
                            SqlJoinType = LeftOuterJoin;

                            column(UOM_TransSale; "Unit of Measure") { }
                            column(UOM_Quantity; "UOM Quantity") { }
                            column(Quantity; Quantity) { }
                            column(UOM_Price; "UOM Price") { }
                            column(Price; Price) { }

                            // ── FIX #2: existence-detection column ──
                            // ต้นฉบับใช้ TransSalesEntryTB.FindFirst() เพื่อรู้ว่า "มี record นี้อยู่จริงไหม"
                            // แล้วถ้ามี ใช้ค่าจาก record นี้ "ทั้งชุด" (แม้บาง field จะเป็น 0/blank)
                            // ไม่ fallback แยกทีละ field ไปที่ Sales Shipment Line
                            // Query แบบ LeftOuterJoin ไม่มี concept "พบ/ไม่พบ record" ให้ report โดยตรง
                            // จึงต้องอาศัย field ที่เป็นส่วนหนึ่งของ primary key (ไม่มีทาง blank/0 ถ้า record มีจริง)
                            // เป็นตัวธงบอกว่า join เจอ record หรือไม่ (ถ้าไม่เจอ LeftOuterJoin จะคืนค่า default/0)
                            column(TransSalesEntry_LineNo; "Line No.") { }

                            // JOIN: Sales Shipment Line — fallback UOM / QTY / Price
                            dataitem(SalesShipmentLine; "Sales Shipment Line")
                            {
                                DataItemLink =
                                    "Order No." = MemberSalesEntry."Document No.",
                                    "Line No." = MemberSalesEntry."Line No.",
                                    "No." = MemberSalesEntry."Item No.";
                                SqlJoinType = LeftOuterJoin;

                                column(Shipment_UOM; "Unit of Measure") { }
                                column(Shipment_Quantity; Quantity) { }
                                column(Shipment_Unit_Price; "Unit Price") { }

                                // ── FIX #2 (ต่อ): existence-detection column สำหรับ Sales Shipment Line ──
                                // ต้นฉบับเช็ค SalesShipmentLineTB.FindFirst() แยกต่างหาก ก่อนจะ assign
                                // ค่า Shipment ทั้งชุด ถ้าไม่เจอ record นี้เลย ต้นฉบับปล่อยค่าเป็น blank/0
                                // (ไม่ได้ assign อะไรเลย) - ต้อง mimic พฤติกรรมนี้ด้วย
                                column(ShipmentLine_LineNo; "Line No.") { }
                            }
                        }
                    }
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
    end;
    // C-AVPWDLSVIP 14/07/2026 > Improve Performance of VIP Report(76092) - น้องปอ
}

report 50104 "Member Sales History"
{
    Caption = 'Member Sales History';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep76092_MemberSalesHistory.rdl';
    PreviewMode = PrintLayout;

    // AVPWDLSVIP 14/07/2026 > Improve Performance of VIP Report(76092) - น้องปอ
    dataset
    {
        // Dummy dataitem: ใช้แค่รับ RequestFilterFields จาก request page
        // ไม่ loop จริง (Break ทันทีใน OnPreDataItem) ค่า filter จะถูกอ่านไปส่งต่อ Query ทีหลัง
        dataitem(MemberContactFilter; "LSC Member Contact")
        {
            RequestFilterFields = "Search Name", "Mobile Phone No.", "PLSWS_ID Card No.";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }

        // Main dataitem: ใช้ Integer วน loop อ่านทีละแถวจาก Query (แทน nested dataitem + FindFirst แบบเดิม)
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter('1..'));

            column(ShowVariant; not RetailSetup."PLSPOS_Show Var for Report VIP") { }
            column(Name_CompanyInforTB; CompanyInfo.Name) { }
            column(DateHeader; DateHeader) { }
            column(CurrDate; Format(CurrDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(CurrTime; Format(CurrTime)) { }

            // อ่านตรงจาก Query
            column(Member_Account_No_; MemberSalesHistoryQ.Member_Account_No_) { }
            column(Description_MemberAcc; MemberSalesHistoryQ.Member_Account_Description) { }
            column(Store_No_; MemberSalesHistoryQ.Store_No_) { }
            column(Document_No_; MemberSalesHistoryQ.Document_No_) { }
            column("Date"; Format(MemberSalesHistoryQ.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(SaleIsReturnSale_TransacH; MemberSalesHistoryQ.Sale_Is_Return_Sale) { }
            column(Item_No_; MemberSalesHistoryQ.Item_No_) { }
            column(Description; MemberSalesHistoryQ.Description) { }
            column(Item_Variant_Code; MemberSalesHistoryQ.Item_Variant_Code) { }
            // UOM/Qty/Price ไม่ได้อ่านตรงจาก Query เพราะต้องผ่าน fallback logic ก่อน (ดู OnAfterGetRecord)
            column(UOM_TransSale; CurrentUOM) { }
            column(QTYTranSale; CurrentQty) { }
            column(PriceTranSale; CurrentPrice) { }
            column(Discount_Amount; MemberSalesHistoryQ.Discount_Amount) { }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                RetailSetup.Get();

                // เคลียร์ทุกครั้งก่อน assign ใหม่ กัน state ค้างจากรอบรันก่อนหน้า
                Clear(CurrDate);
                Clear(CurrTime);
                CurrDate := Today;
                CurrTime := Time;

                Clear(DateFilter);
                Clear(DateHeader);

                // เคลียร์ state ของ dedup logic (ดูเหตุผลที่ OnAfterGetRecord ด้านล่าง)
                Clear(LastEntryNo);
                Clear(LastLineNo);
                Clear(HasLastRead);

                // สร้าง date filter + header text ตามโหมดที่เลือกใน request page
                if ChoosePeriod then begin
                    if (FromDate <> 0D) and (ToDate <> 0D) then begin
                        DateHeader := 'ประจำงวดวันที่ ' + Format(FromDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + Format(ToDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        MemberSalesHistoryQ.SetFilter(DateFilter, '%1..%2', FromDate, ToDate);
                    end;
                end else
                    if ChooseAtDate then begin
                        DateHeader := 'ประจำงวดวันที่ ' + Format(FDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + Format(FDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        MemberSalesHistoryQ.SetFilter(DateFilter, '%1', FDate);
                    end;

                // ส่ง filter จาก request page (MemberContactFilter) เข้า Query ตรงๆ
                if MemberContactFilter.GetFilter("Search Name") <> '' then
                    MemberSalesHistoryQ.SetFilter(SearchNameFilter, MemberContactFilter.GetFilter("Search Name"));
                if MemberContactFilter.GetFilter("Mobile Phone No.") <> '' then
                    MemberSalesHistoryQ.SetFilter(MobilePhoneNoFilter, MemberContactFilter.GetFilter("Mobile Phone No."));
                if MemberContactFilter.GetFilter("PLSWS_ID Card No.") <> '' then
                    MemberSalesHistoryQ.SetFilter(IDCardNoFilter, MemberContactFilter.GetFilter("PLSWS_ID Card No."));

                MemberSalesHistoryQ.Open();
            end;

            trigger OnAfterGetRecord()
            begin
                // อ่านแถวถัดไปจาก Query แล้วข้ามแถวที่ (Entry No., Line No.) ซ้ำกับแถวก่อนหน้า
                // เหตุผล: MemberSalesEntry เป็น driving table ที่ unique อยู่แล้ว แต่ join ชั้นล่าง
                // (TransactionHeader/TransSalesEntry/SalesShipmentLine) เป็น LeftOuterJoin ต่อกันหลายชั้น
                // ถ้าคีย์ join ไม่ unique จริง จะได้แถวคูณออกมาสำหรับ sales entry เดียวกัน
                // การข้ามแถวซ้ำแบบนี้ = เลือกแถวแรกที่เจอ ใกล้เคียงพฤติกรรม FindFirst() ของต้นฉบับ 76092
                repeat
                    if not MemberSalesHistoryQ.Read() then
                        CurrReport.Break();
                until (not HasLastRead) or
                      (MemberSalesHistoryQ.Entry_No_ <> LastEntryNo) or
                      (MemberSalesHistoryQ.Line_No_ <> LastLineNo);

                HasLastRead := true;
                LastEntryNo := MemberSalesHistoryQ.Entry_No_;
                LastLineNo := MemberSalesHistoryQ.Line_No_;

                Clear(CurrentQty);
                Clear(CurrentPrice);
                Clear(CurrentUOM);

                // Fallback logic ตรงกับต้นฉบับ 76092:
                // ถ้า TransSalesEntry มี record จริง (เช็คจาก Line No. ซึ่งเป็นส่วนหนึ่งของ PK ไม่มีทาง 0/blank)
                // ให้ใช้ค่า UOM/Qty/Price จาก TransSalesEntry "ทั้งชุด" แม้บาง field จะเป็น 0 ก็ตาม
                // ไม่ fallback แยกทีละ field ไปที่ Sales Shipment Line
                if MemberSalesHistoryQ.TransSalesEntry_LineNo <> 0 then begin
                    CurrentUOM := MemberSalesHistoryQ.UOM_TransSale;

                    if MemberSalesHistoryQ.UOM_Quantity <> 0 then
                        CurrentQty := MemberSalesHistoryQ.UOM_Quantity * -1
                    else
                        CurrentQty := MemberSalesHistoryQ.Quantity * -1;

                    if MemberSalesHistoryQ.UOM_Price <> 0 then
                        CurrentPrice := MemberSalesHistoryQ.UOM_Price
                    else
                        CurrentPrice := MemberSalesHistoryQ.Price;
                end else
                    // ไม่เจอ TransSalesEntry เลย -> fallback ไป Sales Shipment Line ทั้งชุด (ถ้ามี)
                    if MemberSalesHistoryQ.ShipmentLine_LineNo <> 0 then begin
                        CurrentUOM := MemberSalesHistoryQ.Shipment_UOM;
                        CurrentQty := MemberSalesHistoryQ.Shipment_Quantity;
                        CurrentPrice := MemberSalesHistoryQ.Shipment_Unit_Price;
                    end;
                // ไม่เจอทั้งคู่ -> ปล่อย CurrentUOM/CurrentQty/CurrentPrice เป็นค่า Clear (blank/0) เหมือนต้นฉบับ
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                // Period vs At Date: สอง checkbox นี้ mutual exclusive กันเอง ผ่าน OnValidate ของแต่ละตัว
                group("Filter")
                {
                    field("Period"; ChoosePeriod)
                    {
                        Caption = 'Period';
                        Style = Strong;
                        StyleExpr = true;
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            if ChoosePeriod then
                                ChooseAtDate := false
                            else
                                ChooseAtDate := true;
                        end;
                    }
                    field("Start Date"; FromDate)
                    {
                        Caption = 'Start Date';
                        ApplicationArea = All;
                        Enabled = ChoosePeriod;
                    }
                    field("End Date"; ToDate)
                    {
                        Caption = 'End Date';
                        ApplicationArea = All;
                        Enabled = ChoosePeriod;

                        trigger OnValidate()
                        begin
                            if ToDate < FromDate then
                                Error('End Date < Start Date');
                        end;
                    }
                    field("At Date"; ChooseAtDate)
                    {
                        Caption = 'At Date';
                        Style = Strong;
                        StyleExpr = true;
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            if ChooseAtDate then
                                ChoosePeriod := false
                            else
                                ChoosePeriod := true;
                        end;
                    }
                    field("Date"; FDate)
                    {
                        Caption = 'Date';
                        ApplicationArea = All;
                        Enabled = ChooseAtDate;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            // ค่าเริ่มต้น: โหมด At Date วันนี้
            FDate := Today;
            ChoosePeriod := false;
            ChooseAtDate := true;
        end;
    }

    var
        CompanyInfo: Record "Company Information";
        RetailSetup: Record "LSC Retail Setup";
        MemberSalesHistoryQ: Query "MemberSalesHistory Q";

        // Request page: ตัวเลือกช่วงวันที่จากผู้ใช้
        FromDate: Date;
        ToDate: Date;
        FDate: Date;
        ChoosePeriod: Boolean;
        ChooseAtDate: Boolean;

        // Header ของรายงาน
        DateHeader: Text[50];
        DateFilter: Text[50];
        CurrDate: Date;
        CurrTime: Time;

        // ค่าที่ผ่าน fallback logic แล้ว ใช้แสดงผลจริงใน column UOM/Qty/Price
        CurrentUOM: Text[50];
        CurrentQty: Decimal;
        CurrentPrice: Decimal;

        // State สำหรับกันแถวซ้ำจาก LeftOuterJoin ใน Query (ดูรายละเอียดที่ OnAfterGetRecord)
        LastEntryNo: Integer;
        LastLineNo: Integer;
        HasLastRead: Boolean;
}
//C-AVPWDLSVIP 14/07/2026 > Improve Performance of VIP Report(76092) - น้องปอ

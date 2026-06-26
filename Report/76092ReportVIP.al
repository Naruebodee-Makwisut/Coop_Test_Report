report 50104 "Member Sales History"
{
    Caption = 'Member Sales History';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50104_MemberSalesHistory.rdl';
    PreviewMode = PrintLayout;

    // AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76092) - น้องปอ
    dataset
    {
        // ── Dummy dataitem 1: รับ RequestFilterFields สำหรับ Member Contact ──
        // ทำหน้าที่แค่เก็บ filter ที่ user กรอกใน Request Page
        // ไม่ได้วน loop จริง (Break() ใน OnPreDataItem)
        dataitem(MemberContactFilter; "LSC Member Contact")
        {
            RequestFilterFields = "Search Name", "Mobile Phone No.", "PLSWS_ID Card No.";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }

        // ── Main dataitem: ใช้ Integer วน loop อ่านจาก Query ──
        // แทนที่ nested dataitem เดิมที่ต้อง FindFirst() ทีละ record
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter('1..'));

            // Header columns
            column(ShowVariant; not RetailSetup."PLSPOS_Show Var for Report VIP") { }
            column(Name_CompanyInforTB; CompanyInfo.Name) { }
            column(DateHeader; DateHeader) { }
            column(CurrDate; Format(CurrDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(CurrTime; Format(CurrTime)) { }

            // Data columns — อ่านค่าจาก Current* variables ที่ fill จาก Query
            column(Member_Account_No_; CurrentMemberAccountNo) { }
            column(Description_MemberAcc; CurrentMemberAccountDesc) { }
            column(Store_No_; CurrentStoreNo) { }
            column(Document_No_; CurrentDocumentNo) { }
            column("Date"; Format(CurrentDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(SaleIsReturnSale_TransacH; CurrentSaleIsReturnSale) { }
            column(Item_No_; CurrentItemNo) { }
            column(Description; CurrentDescription) { }
            column(Item_Variant_Code; CurrentItemVariantCode) { }
            column(UOM_TransSale; CurrentUOM) { }
            column(QTYTranSale; CurrentQty) { }
            column(PriceTranSale; CurrentPrice) { }
            column(Discount_Amount; CurrentDiscountAmount) { }

            trigger OnPreDataItem()
            begin
                // ── Setup header info ──
                CompanyInfo.Get();
                RetailSetup.Get();

                CurrDate := Today;
                CurrTime := Time;

                // ── Build date filter string และ header text ──
                Clear(DateFilter);
                Clear(DateHeader);

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

                // ── ส่ง filter Member Contact จาก RequestFilterFields ไปที่ Query ──
                // ส่ง filter ของแต่ละ field ตรงๆ ไปที่ Query แทนการ resolve เป็น Contact No.
                // เพราะการสะสม pipe string อาจเกิน Text limit เมื่อมี Contact เยอะ
                if MemberContactFilter.GetFilter("Search Name") <> '' then
                    MemberSalesHistoryQ.SetFilter(SearchNameFilter, MemberContactFilter.GetFilter("Search Name"));
                if MemberContactFilter.GetFilter("Mobile Phone No.") <> '' then
                    MemberSalesHistoryQ.SetFilter(MobilePhoneNoFilter, MemberContactFilter.GetFilter("Mobile Phone No."));
                if MemberContactFilter.GetFilter("PLSWS_ID Card No.") <> '' then
                    MemberSalesHistoryQ.SetFilter(IDCardNoFilter, MemberContactFilter.GetFilter("PLSWS_ID Card No."));

                // ── เปิด Query — SQL จะ JOIN ทุกตารางในครั้งเดียว ──
                MemberSalesHistoryQ.Open();
            end;

            trigger OnAfterGetRecord()
            begin
                // อ่าน record ถัดไปจาก Query
                // ถ้าหมดแล้วให้ Break ออกจาก loop
                if not MemberSalesHistoryQ.Read() then
                    CurrReport.Break();

                // ── Fill current variables จากผล Query ──
                CurrentMemberAccountNo := MemberSalesHistoryQ.Member_Account_No_;
                CurrentMemberAccountDesc := MemberSalesHistoryQ.Member_Account_Description;
                CurrentStoreNo := MemberSalesHistoryQ.Store_No_;
                CurrentDocumentNo := MemberSalesHistoryQ.Document_No_;
                CurrentDate := MemberSalesHistoryQ.Date;
                CurrentSaleIsReturnSale := MemberSalesHistoryQ.Sale_Is_Return_Sale;
                CurrentItemNo := MemberSalesHistoryQ.Item_No_;
                CurrentDescription := MemberSalesHistoryQ.Description;
                CurrentItemVariantCode := MemberSalesHistoryQ.Item_Variant_Code;
                CurrentDiscountAmount := MemberSalesHistoryQ.Discount_Amount;

                // ── ตรรกะ UOM / QTY / Price เดิม แต่อ่านจาก Query แทน FindFirst() ──
                // Priority 1: Trans. Sales Entry (JOIN อยู่แล้วใน Query)
                if MemberSalesHistoryQ.UOM_Quantity <> 0 then
                    CurrentQty := MemberSalesHistoryQ.UOM_Quantity * -1
                else
                    if MemberSalesHistoryQ.Quantity <> 0 then
                        CurrentQty := MemberSalesHistoryQ.Quantity * -1
                    else
                        // Priority 2: Sales Shipment Line (fallback JOIN ใน Query)
                        CurrentQty := MemberSalesHistoryQ.Shipment_Quantity;

                if MemberSalesHistoryQ.UOM_Price <> 0 then
                    CurrentPrice := MemberSalesHistoryQ.UOM_Price
                else
                    if MemberSalesHistoryQ.Price <> 0 then
                        CurrentPrice := MemberSalesHistoryQ.Price
                    else
                        CurrentPrice := MemberSalesHistoryQ.Shipment_Unit_Price;

                if MemberSalesHistoryQ.UOM_TransSale <> '' then
                    CurrentUOM := MemberSalesHistoryQ.UOM_TransSale
                else
                    CurrentUOM := MemberSalesHistoryQ.Shipment_UOM;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
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
            FDate := Today;
            ChoosePeriod := false;
            ChooseAtDate := true;
        end;
    }

    var
        CompanyInfo: Record "Company Information";
        RetailSetup: Record "LSC Retail Setup";
        MemberSalesHistoryQ: Query "MemberSalesHistory Q";  // Query ใหม่ที่ join ทุกตาราง

        // Request Page variables
        FromDate: Date;
        ToDate: Date;
        FDate: Date;
        ChoosePeriod: Boolean;
        ChooseAtDate: Boolean;

        // Header display variables
        DateHeader: Text[50];
        DateFilter: Text[50];
        CurrDate: Date;
        CurrTime: Time;

        // Current record variables (fill จาก Query ใน OnAfterGetRecord)
        CurrentMemberAccountNo: Code[20];
        CurrentMemberAccountDesc: Text[100];
        CurrentStoreNo: Code[20];
        CurrentDocumentNo: Code[20];
        CurrentDate: Date;
        CurrentSaleIsReturnSale: Boolean;
        CurrentItemNo: Code[20];
        CurrentDescription: Text[100];
        CurrentItemVariantCode: Code[20];
        CurrentDiscountAmount: Decimal;
        CurrentUOM: Text[50];
        CurrentQty: Decimal;
        CurrentPrice: Decimal;
    // C-AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76092) - น้องปอ
}

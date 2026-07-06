report 50103 "Member Balance Point"
{
    Caption = 'Member Balance Point';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50103_MemberBalancePoint.rdl';
    PreviewMode = PrintLayout;
    // MaximumDocumentCount = 500;
    // MaximumDatasetSize = 10000000;

    // AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76094)
    dataset
    {
        // dataitem: โหลดข้อมูลทั้งหมดใส่ Temp Table ให้เสร็จก่อน
        dataitem(MemberAccountLoader; "LSC Member Account")
        {
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            begin
                if (FromDateFilter = 0D) or (TodateFilter = 0D) then
                    Error('Please fill filter date!');

                PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')
                            + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

                if MemberAccountLoader.GetFilters <> '' then
                    ReportFilterText := MemberAccountLoader.GetFilters;

                clear(AVTempMemberTB);
                if AVTempMemberTB.IsTemporary then
                    AVTempMemberTB.DeleteAll();

                //======================ยืม field ใช้ใน table temp=============================
                // PointBF>>"Expired Points"
                // PointEarned>>"Issued Award Points"
                // PointRedeemed>>"Used Points"
                // PointAdjust>>"Issued Other Points"
                // PointExpire>>"Expiration in Period"

                //======================แบบออกทุก Account No.=============================
                // === Step 1: ใส่ทุก Member Account ลง Temp Table ก่อนเลย (ค่า Point เป็น 0 หมด) ===
                Clear(MemberAccountTB);
                if MemberAccountLoader.GetFilter("No.") <> '' then
                    MemberAccountTB.SetFilter("No.", MemberAccountLoader.GetFilter("No."));
                if MemberAccountTB.FindSet() then
                    repeat
                        Clear(AVTempMemberTB);
                        AVTempMemberTB.Init();
                        AVTempMemberTB."No." := MemberAccountTB."No.";
                        AVTempMemberTB.Description := MemberAccountTB.Description;
                        AVTempMemberTB.Insert();
                    until MemberAccountTB.Next() = 0;

                // === Step 2: Query BF → update Temp Table ===
                QueryPointBF.SetFilter(Date, '..%1', FromDateFilter - 1);
                if MemberAccountLoader.GetFilter("No.") <> '' then
                    QueryPointBF.SetFilter(Account_No, MemberAccountLoader.GetFilter("No."));
                QueryPointBF.Open();
                while QueryPointBF.Read() do begin
                    AVTempMemberTB.Reset();  // ← Reset แทน Clear เพื่อล้าง filter เฉยๆ ไม่ล้าง record
                    AVTempMemberTB.SetRange("No.", QueryPointBF.Account_No_);
                    if AVTempMemberTB.FindFirst() then begin
                        AVTempMemberTB."Expired Points" += QueryPointBF.Points;
                        AVTempMemberTB.Modify();
                    end;
                end;

                // === Step 3: Query In Period → update Temp Table ===
                QueryPointInPeriod.SetFilter(Date, '%1..%2', FromDateFilter, TodateFilter);
                if MemberAccountLoader.GetFilter("No.") <> '' then
                    QueryPointInPeriod.SetFilter(Account_No, MemberAccountLoader.GetFilter("No."));
                QueryPointInPeriod.Open();
                while QueryPointInPeriod.Read() do begin
                    AVTempMemberTB.Reset();  // ← Reset แทน Clear
                    AVTempMemberTB.SetRange("No.", QueryPointInPeriod.Account_No_);
                    if AVTempMemberTB.FindFirst() then begin
                        case QueryPointInPeriod.Entry_Type of
                            QueryPointInPeriod.Entry_Type::Sales:
                                AVTempMemberTB."Issued Award Points" += QueryPointInPeriod.Points;
                            QueryPointInPeriod.Entry_Type::Redemption:
                                AVTempMemberTB."Used Points" += QueryPointInPeriod.Points;
                            QueryPointInPeriod.Entry_Type::"Positive Adjmt.",
                            QueryPointInPeriod.Entry_Type::"Negative Adjmt":
                                AVTempMemberTB."Issued Other Points" += QueryPointInPeriod.Points;
                            QueryPointInPeriod.Entry_Type::Expire:
                                AVTempMemberTB."Expiration in Period" += QueryPointInPeriod.Points;
                        end;
                        AVTempMemberTB.Modify();
                    end;
                end;

                CurrReport.Break();
                //======================แบบออกทุก Account No.=============================

                //======================แบบออกเฉพาะ Account No.ที่มีใน Member Point=============================
                // // === โหลด BF ===
                // QueryPointBF.SetFilter(Date, '..%1', FromDateFilter - 1);
                // if MemberAccountLoader.GetFilter("No.") <> '' then
                //     QueryPointBF.SetFilter(Account_No, MemberAccountLoader.GetFilter("No."));
                // QueryPointBF.Open();
                // while QueryPointBF.Read() do begin
                //     Clear(AVTempMemberTB);
                //     AVTempMemberTB.SetRange("No.", QueryPointBF.Account_No_);
                //     if AVTempMemberTB.FindFirst() then begin
                //         AVTempMemberTB."Expired Points" += QueryPointBF.Points;
                //         AVTempMemberTB.Modify();
                //     end else begin
                //         Clear(AVTempMemberTB);
                //         AVTempMemberTB.Init();
                //         AVTempMemberTB."No." := QueryPointBF.Account_No_;
                //         AVTempMemberTB."Expired Points" += QueryPointBF.Points;
                //         AVTempMemberTB.Insert();
                //     end;
                // end;

                // // === โหลด In Period แยก Entry Type ===
                // QueryPointInPeriod.SetFilter(Date, '%1..%2', FromDateFilter, TodateFilter);
                // if MemberAccountLoader.GetFilter("No.") <> '' then
                //     QueryPointInPeriod.SetFilter(Account_No, MemberAccountLoader.GetFilter("No."));
                // QueryPointInPeriod.Open();
                // while QueryPointInPeriod.Read() do begin
                //     Clear(AVTempMemberTB);
                //     AVTempMemberTB.SetRange("No.", QueryPointInPeriod.Account_No_);
                //     if not AVTempMemberTB.FindFirst() then begin
                //         Clear(AVTempMemberTB);
                //         AVTempMemberTB.Init();
                //         AVTempMemberTB."No." := QueryPointInPeriod.Account_No_;
                //         AVTempMemberTB.Insert();
                //     end;
                //     case QueryPointInPeriod.Entry_Type of
                //         QueryPointInPeriod.Entry_Type::Sales:
                //             AVTempMemberTB."Issued Award Points" += QueryPointInPeriod.Points;
                //         QueryPointInPeriod.Entry_Type::Redemption:
                //             AVTempMemberTB."Used Points" += QueryPointInPeriod.Points;
                //         QueryPointInPeriod.Entry_Type::"Positive Adjmt.",
                //         QueryPointInPeriod.Entry_Type::"Negative Adjmt":
                //             AVTempMemberTB."Issued Other Points" += QueryPointInPeriod.Points;
                //         QueryPointInPeriod.Entry_Type::Expire:
                //             AVTempMemberTB."Expiration in Period" += QueryPointInPeriod.Points;
                //     end;
                //     AVTempMemberTB.Modify();
                // end;

                // // โหลดเสร็จแล้ว Break ทิ้ง
                // CurrReport.Break();
                //======================แบบออกเฉพาะ Account No.ที่มีใน Member Point=============================
            end;
        }

        // Integer: ทำหน้าที่แค่ loop Temp Table ส่งไป RDLC เท่านั้น
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));

            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(FromDateFilter_D1; FORMAT(FromDateFilter - 1, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(FromDateFilter; FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(TodateFilter; FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(ReportFilterText; ReportFilterText) { }
            column(No_MemberAccount; AVTempMemberTB."No.") { }
            column(Description_MemberAccount; AVTempMemberTB.Description) { }
            column(PointBF; AVTempMemberTB."Expired Points") { }
            column(PointEarned; AVTempMemberTB."Issued Award Points") { }
            column(PointRedeemed; AVTempMemberTB."Used Points") { }
            column(PointAdjust; AVTempMemberTB."Issued Other Points") { }
            column(PointExpire; AVTempMemberTB."Expiration in Period") { }
            column(PointBalance; AVTempMemberTB."Expired Points"
                    + AVTempMemberTB."Issued Award Points"
                    + AVTempMemberTB."Used Points"
                    + AVTempMemberTB."Issued Other Points"
                    + AVTempMemberTB."Expiration in Period")
            { }

            trigger OnPreDataItem()
            begin
                ComInfo.Get();
                ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                ShowTime := LSVIPRepFunction.AVTimeFormat(Time);

                // Reset ไว้ก่อน ยังไม่ FindSet ที่นี่
                AVTempMemberTB.Reset();
                if AVTempMemberTB.IsEmpty() then
                    CurrReport.Break();
            end;

            trigger OnAfterGetRecord()
            begin
                // Number=1 → FindFirst, Number>1 → Next()
                if Number = 1 then begin
                    if not AVTempMemberTB.FindFirst() then
                        CurrReport.Break();
                end else
                    if AVTempMemberTB.Next() = 0 then
                        CurrReport.Break();

                // ดึง Description
                Clear(MemberAccountTB);
                if MemberAccountTB.Get(AVTempMemberTB."No.") then
                    AVTempMemberTB.Description := MemberAccountTB.Description;
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
                    field(FromDate; FromDateFilter)
                    {
                        Caption = 'Start Date';
                        ApplicationArea = All;
                    }
                    field(ToDate; TodateFilter)
                    {
                        Caption = 'End Date';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            IF TodateFilter < FromDateFilter THEN
                                ERROR('End Date < Start Date');
                        end;
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    var
        ComInfo: Record "Company Information";
        MemberAccountTB: Record "LSC Member Account";
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        AVTempMemberTB: Record "LSC Member Account" temporary;
        QueryPointBF: Query "Member Point BF Q";
        QueryPointInPeriod: Query "Member Point Period Q";
        DateFilter: Text[100];
        PeriodDate: Text[150];
        ReportFilterText: Text;
        ShowTime: Text[50];
        ShowDate: Text[50];
        FromDateFilter: Date;
        TodateFilter: Date;
        FinishedLoadingBF: Boolean;
        FinishedLoadingPeriod: Boolean;
        FinishedLoading: Boolean;
        CurrentPointEarned: Decimal;
        CurrentPointRedeemed: Decimal;
        CurrentPointAdjust: Decimal;
        CurrentPointExpire: Decimal;
        CurrentPointBalance: Decimal;

    // C-AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76094)
}
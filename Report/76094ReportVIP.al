report 50103 "Member Balance Point"
{
    Caption = 'Member Balance Point';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50103_MemberBalancePoint.rdl';
    PreviewMode = PrintLayout;
    MaximumDocumentCount = 500;
    MaximumDatasetSize = 10000000;

         dataset
        {
            // ── Main dataitem: วิ่งตาม LSC Member Account โดยตรง ──
            // เป็น driver หลัก ทุก Member Account = 1 row ในรายงานเสมอ
            // ไม่ขึ้นกับว่ามี Point Entry ก่อนช่วงหรือเปล่า
            dataitem("LSC Member Account";"LSC Member Account"){
                DataItemTableView = sorting("No.");
                RequestFilterFields = "No.";
                trigger OnPreDataItem() begin
                    CurrReport.Break();
                end;
            }
            dataitem("LSC Member Point Entry";"LSC Member Point Entry"){
                trigger OnPreDataItem() begin

                end;
            }
            dataitem(MemberAccount; "LSC Member Account")
            {
                DataItemTableView = sorting("No.");
                // RequestFilterFields = "No.";

                column(Name_ComInfo; ComInfo.Name) { }
                column(ShowDate; ShowDate) { }
                column(ShowTime; ShowTime) { }
                column(PeriodDate; PeriodDate) { }
                column(FromDateFilter_D1; FromDateFilter_D1_Txt) { }
                column(FromDateFilter; Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
                column(TodateFilter; Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
                column(ReportFilterText; ReportFilterText) { }
                column(No_MemberAccount; "No.") { }
                column(Description_MemberAccount; Description) { }
                column(PointBF; PointBF) { }
                column(PointEarned; PointEarned) { }
                column(PointRedeemed; PointRedeemed) { }
                column(PointAdjust; PointAdjust) { }
                column(PointExpire; PointExpire) { }
                column(PointBalance; PointBalance) { }

                trigger OnPreDataItem()
                begin
                    if (FromDateFilter = 0D) or (TodateFilter = 0D) then
                        Error('Please fill filter date!');

                    // คำนวณ FromDate-1 หลัง guard เพื่อป้องกัน crash ตอน FromDateFilter = 0D
                    FromDateFilter_D1_Txt := Format(FromDateFilter - 1, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

                    PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')
                                + ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

                    if MemberAccount.GetFilters <> '' then
                        ReportFilterText := MemberAccount.GetFilters;

                    // ── Open BF Query (0D..FromDate-1) ──
                    // ส่ง Account filter เดียวกับ dataitem เพื่อไม่ดึงข้อมูล Account ที่ไม่เกี่ยว
                    BFQuery.SetFilter(DateFilter, '%1..%2', 0D, FromDateFilter - 1);
                    if MemberAccount.GetFilter("No.") <> '' then
                        BFQuery.SetFilter(AccountNoFilter, MemberAccount.GetFilter("No."));
                    BFQuery.Open();
                    BFQueryHasData := BFQuery.Read();   // อ่านล่วงหน้า record แรก

                    // ── Open Period Query (FromDate..ToDate) ──
                    PeriodQuery.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
                    if MemberAccount.GetFilter("No.") <> '' then
                        PeriodQuery.SetFilter(AccountNoFilter, MemberAccount.GetFilter("No."));
                    PeriodQuery.Open();
                    PeriodQueryHasData := PeriodQuery.Read(); // อ่านล่วงหน้า record แรก
                end;

                trigger OnAfterGetRecord()
                begin
                    AV_ClearVar();

                    // ── PointBF: ดึงจาก BF Query ──
                    // BF Query เรียงตาม Account_No_ เหมือนกับ dataitem
                    // ถ้า Account ปัจจุบันมี record ใน BF Query → เอาค่า, แล้วเลื่อนไป record ถัดไป
                    // ถ้าไม่มี (Member ใหม่ที่ยังไม่เคยมี Point) → PointBF = 0 ตาม AV_ClearVar()
                    if BFQueryHasData then begin
                        if BFQuery.Account_No_ = MemberAccount."No." then begin
                            PointBF := BFQuery.Total_Points;
                            BFQueryHasData := BFQuery.Read();
                        end;
                    end;
                    PointBalance := PointBF;

                    // ── PointEarned/Redeemed/Adjust/Expire: ดึงจาก Period Query ──
                    // Period Query เรียงตาม Account_No_, Entry_Type
                    // วน Read() ตราบที่ยังเป็น Account เดิมอยู่
                    if PeriodQueryHasData then
                        if PeriodQuery.Account_No_ = MemberAccount."No." then begin
                            repeat
                                case PeriodQuery.Entry_Type of
                                    PeriodQuery.Entry_Type::Sales:
                                        PointEarned += PeriodQuery.Total_Points;
                                    PeriodQuery.Entry_Type::Redemption:
                                        PointRedeemed += PeriodQuery.Total_Points;
                                    PeriodQuery.Entry_Type::"Positive Adjmt.":
                                        PointAdjust += PeriodQuery.Total_Points;
                                    PeriodQuery.Entry_Type::"Negative Adjmt":
                                        PointAdjust += PeriodQuery.Total_Points;
                                    PeriodQuery.Entry_Type::Expire:
                                        PointExpire += PeriodQuery.Total_Points;
                                end;

                                PeriodQueryHasData := PeriodQuery.Read();

                                if not PeriodQueryHasData then
                                    exit_loop := true
                                else
                                    if PeriodQuery.Account_No_ <> MemberAccount."No." then
                                        exit_loop := true;

                            until exit_loop;
                        end;

                    PointBalance += PointEarned + PointRedeemed + PointAdjust + PointExpire;
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
                                if TodateFilter < FromDateFilter then
                                    Error('End Date < Start Date');
                            end;
                        }
                    }
                }
            }
        }

        trigger OnPreReport()
        begin
            ComInfo.Get();
            ShowDate := Format(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
            ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
        end;

        var
            LSVIPRepFunction: Codeunit "PLSR_Report Function";
            ComInfo: Record "Company Information";

            BFQuery: Query "PLSR_Member Point BF Q";
            PeriodQuery: Query "PLSR_Member Point Period Q";

            // Lookahead flags
            BFQueryHasData: Boolean;
            PeriodQueryHasData: Boolean;

            // Request Page
            FromDateFilter: Date;
            TodateFilter: Date;

            // Header
            DateFilter: Text[100];
            PeriodDate: Text[150];
            ReportFilterText: Text;
            ShowTime: Text[50];
            ShowDate: Text[50];
            FromDateFilter_D1_Txt: Text[20];  // เก็บ Format(FromDate-1) หลัง guard แล้ว

            // Point accumulators
            PointBF: Decimal;
            PointEarned: Decimal;
            PointRedeemed: Decimal;
            PointAdjust: Decimal;
            PointExpire: Decimal;
            PointBalance: Decimal;

            exit_loop: Boolean;

        local procedure AV_ClearVar()
        begin
            Clear(PointBF);
            Clear(PointEarned);
            Clear(PointRedeemed);
            Clear(PointAdjust);
            Clear(PointExpire);
            Clear(PointBalance);
        end;

    // =============================================================================================================

    // dataset
    // {
    //     // dataitem หลอก 1: รับ filter "No." จาก user
    //     dataitem("LSC Member Account"; "LSC Member Account")
    //     {
    //         DataItemTableView = sorting("No.");
    //         RequestFilterFields = "No.";
    //         trigger OnPreDataItem()
    //         begin
    //             CurrReport.Break();
    //         end;
    //     }

    //     // dataitem หลอก 2: วิ่งเฉพาะกรณีไม่มี filter "No."
    //     // สะสม Point ลง Temp แล้วหยุด
    //     dataitem("LSC Member Point Entry"; "LSC Member Point Entry")
    //     {
    //         DataItemTableView = sorting("Account No.", Date, "Entry Type");

    //         trigger OnPreDataItem()
    //         begin
    //             // มี filter "No." → ข้ามไปเลย ให้ MemberAccount dataitem ทำงานแทน
    //             if "LSC Member Account".GetFilter("No.") <> '' then begin
    //                 CurrReport.Break();
    //                 exit;
    //             end;

    //             if (FromDateFilter = 0D) or (TodateFilter = 0D) then
    //                 Error('Please fill filter date!');

    //             FromDateFilter_D1_Txt := Format(FromDateFilter - 1, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
    //             PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
    //                           ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

    //             // กรองเฉพาะ Entry ในช่วงวันที่
    //             "LSC Member Point Entry".SetRange(Date, FromDateFilter, TodateFilter);
    //             "LSC Member Point Entry".SetLoadFields("Account No.", "Entry Type", Points);

    //             // เตรียม Temp ไว้รับค่า
    //             TempPointEntryTB.Reset();
    //             TempPointEntryTB.DeleteAll();
    //             TempEntryNo := 1;
    //         end;

    //         trigger OnAfterGetRecord()
    //         begin
    //             // ── สะสม Period Point ลง Temp แยกตาม Account ──
    //             TempPointEntryTB.SetRange("Account No.", "LSC Member Point Entry"."Account No.");
    //             if not TempPointEntryTB.FindFirst() then begin
    //                 TempPointEntryTB.Init();
    //                 TempPointEntryTB."Entry No." := TempEntryNo;  // ใช้ counter แทน PK
    //                 TempPointEntryTB."Account No." := "LSC Member Point Entry"."Account No.";
    //                 TempPointEntryTB.Insert();
    //                 TempEntryNo += 1;
    //             end;

    //             case "LSC Member Point Entry"."Entry Type" of
    //                 "LSC Member Point Entry"."Entry Type"::Sales:
    //                     TempPointEntryTB.Points += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::Redemption:
    //                     TempPointEntryTB."Point Value" += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::"Positive Adjmt.":
    //                     TempPointEntryTB."Posting Value" += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::"Negative Adjmt":
    //                     TempPointEntryTB."Posting Value" += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::Expire:
    //                     TempPointEntryTB."Remaining Points" += "LSC Member Point Entry".Points;
    //             end;
    //             TempPointEntryTB.Modify();
    //             TempPointEntryTB.Reset();
    //         end;
    //     }

    //     // dataitem หลัก: output 1 row ต่อ 1 Account
    //     dataitem(MemberAccount; "LSC Member Account")
    //     {
    //         DataItemTableView = sorting("No.");

    //         column(Name_ComInfo; ComInfo.Name) { }
    //         column(ShowDate; ShowDate) { }
    //         column(ShowTime; ShowTime) { }
    //         column(PeriodDate; PeriodDate) { }
    //         column(FromDateFilter_D1; FromDateFilter_D1_Txt) { }
    //         column(FromDateFilter; Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
    //         column(TodateFilter; Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
    //         column(ReportFilterText; ReportFilterText) { }
    //         column(No_MemberAccount; "No.") { }
    //         column(Description_MemberAccount; Description) { }
    //         column(PointBF; PointBF) { }
    //         column(PointEarned; PointEarned) { }
    //         column(PointRedeemed; PointRedeemed) { }
    //         column(PointAdjust; PointAdjust) { }
    //         column(PointExpire; PointExpire) { }
    //         column(PointBalance; PointBalance) { }

    //         trigger OnPreDataItem()
    //         begin
    //             if (FromDateFilter = 0D) or (TodateFilter = 0D) then
    //                 Error('Please fill filter date!');

    //             FromDateFilter_D1_Txt := Format(FromDateFilter - 1, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
    //             PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
    //                           ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

    //             if "LSC Member Account".GetFilter("No.") <> '' then begin
    //                 // ── กรณีมี filter "No." ── ใช้ Query เหมือนเดิม
    //                 MemberAccount.SetFilter("No.", "LSC Member Account".GetFilter("No."));
    //                 ReportFilterText := "LSC Member Account".GetFilters;

    //                 BFQuery.SetFilter(DateFilter, '%1..%2', 0D, FromDateFilter - 1);
    //                 BFQuery.SetFilter(AccountNoFilter, "LSC Member Account".GetFilter("No."));
    //                 BFQuery.Open();
    //                 BFQueryHasData := BFQuery.Read();

    //                 PeriodQuery.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
    //                 PeriodQuery.SetFilter(AccountNoFilter, "LSC Member Account".GetFilter("No."));
    //                 PeriodQuery.Open();
    //                 PeriodQueryHasData := PeriodQuery.Read();

    //                 UseQuery := true;
    //             end else begin
    //                 // ── กรณีไม่มี filter "No." ── อ่านจาก Temp ที่สะสมไว้แล้ว
    //                 // กรอง MemberAccount ให้วิ่งเฉพาะ Account ที่มีใน Temp
    //                 if TempPointEntryTB.FindSet() then begin
    //                     FilterTxt := '';
    //                     repeat
    //                         if FilterTxt <> '' then FilterTxt += '|';
    //                         FilterTxt += TempPointEntryTB."Account No.";
    //                     until TempPointEntryTB.Next() = 0;
    //                     MemberAccount.SetFilter("No.", FilterTxt);
    //                 end else
    //                     CurrReport.Break(); // ไม่มีข้อมูลเลย

    //                 // BF Query สำหรับ Account ที่มีใน Temp
    //                 BFQuery.SetFilter(DateFilter, '%1..%2', 0D, FromDateFilter - 1);
    //                 BFQuery.SetFilter(AccountNoFilter, FilterTxt);
    //                 BFQuery.Open();
    //                 BFQueryHasData := BFQuery.Read();

    //                 UseQuery := false;
    //             end;
    //         end;

    //         trigger OnAfterGetRecord()
    //         begin
    //             AV_ClearVar();
    //             exit_loop := false;

    //             // ── PointBF จาก BFQuery เสมอ (ทั้ง 2 กรณี) ──
    //             // แยก condition ออกมาเพื่อหลีกเลี่ยง error
    //             while BFQueryHasData do begin
    //                 if BFQuery.Account_No_ >= MemberAccount."No." then
    //                     break;
    //                 BFQueryHasData := BFQuery.Read();
    //             end;

    //             if BFQueryHasData then
    //                 if BFQuery.Account_No_ = MemberAccount."No." then begin
    //                     PointBF := BFQuery.Total_Points;
    //                     BFQueryHasData := BFQuery.Read();
    //                 end;
    //             PointBalance := PointBF;

    //             if UseQuery then begin
    //                 // ── กรณีมี filter "No." → อ่านจาก PeriodQuery ──
    //                 if PeriodQueryHasData then
    //                     if PeriodQuery.Account_No_ = MemberAccount."No." then
    //                         repeat
    //                             case PeriodQuery.Entry_Type of
    //                                 PeriodQuery.Entry_Type::Sales:
    //                                     PointEarned += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::Redemption:
    //                                     PointRedeemed += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::"Positive Adjmt.":
    //                                     PointAdjust += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::"Negative Adjmt":
    //                                     PointAdjust += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::Expire:
    //                                     PointExpire += PeriodQuery.Total_Points;
    //                             end;
    //                             PeriodQueryHasData := PeriodQuery.Read();
    //                             if not PeriodQueryHasData then
    //                                 exit_loop := true
    //                             else
    //                                 if PeriodQuery.Account_No_ <> MemberAccount."No." then
    //                                     exit_loop := true;
    //                         until exit_loop;
    //             end else begin
    //                 // แทนที่ TempPointEntryTB.Get(MemberAccount."No.")
    //                 TempPointEntryTB.SetRange("Account No.", MemberAccount."No.");
    //                 if TempPointEntryTB.FindFirst() then begin
    //                     PointEarned := TempPointEntryTB.Points;
    //                     PointRedeemed := TempPointEntryTB."Point Value";
    //                     PointAdjust := TempPointEntryTB."Posting Value";
    //                     PointExpire := TempPointEntryTB."Remaining Points";
    //                 end;
    //             end;

    //             PointBalance += PointEarned + PointRedeemed + PointAdjust + PointExpire;
    //         end;
    //     }
    // }

    // requestpage
    // {
    //     layout
    //     {
    //         area(Content)
    //         {
    //             group("Filter")
    //             {
    //                 field(FromDate; FromDateFilter)
    //                 {
    //                     Caption = 'Start Date';
    //                     ApplicationArea = All;
    //                 }
    //                 field(ToDate; TodateFilter)
    //                 {
    //                     Caption = 'End Date';
    //                     ApplicationArea = All;

    //                     trigger OnValidate()
    //                     begin
    //                         if TodateFilter < FromDateFilter then
    //                             Error('End Date < Start Date');
    //                     end;
    //                 }
    //             }
    //         }
    //     }
    // }
    // trigger OnPreReport()
    // begin
    //     ComInfo.Get();
    //     ShowDate := Format(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
    //     ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    // end;

    // var
    //     LSVIPRepFunction: Codeunit "PLSR_Report Function";
    //     ComInfo: Record "Company Information";
    //     BFQuery: Query "PLSR_Member Point BF Q";
    //     PeriodQuery: Query "PLSR_Member Point Period Q";
    //     TempPointEntryTB: Record "LSC Member Point Entry" temporary;
    //     BFQueryHasData: Boolean;
    //     PeriodQueryHasData: Boolean;
    //     UseQuery: Boolean;
    //     FilterTxt: Text;
    //     FromDateFilter: Date;
    //     TodateFilter: Date;
    //     PeriodDate: Text[150];
    //     ReportFilterText: Text;
    //     ShowTime: Text[50];
    //     ShowDate: Text[50];
    //     FromDateFilter_D1_Txt: Text[20];
    //     PointBF: Decimal;
    //     PointEarned: Decimal;
    //     PointRedeemed: Decimal;
    //     PointAdjust: Decimal;
    //     PointExpire: Decimal;
    //     PointBalance: Decimal;
    //     exit_loop: Boolean;
    //     TempEntryNo: Integer;  // counter สำหรับ PK ของ Temp

    // local procedure AV_ClearVar()
    // begin
    //     Clear(PointBF);
    //     Clear(PointEarned);
    //     Clear(PointRedeemed);
    //     Clear(PointAdjust);
    //     Clear(PointExpire);
    //     Clear(PointBalance);
    //     exit_loop := false;
    // end;

    // ===========================================================================================
    //  dataset
    // {
    //     dataitem("LSC Member Account"; "LSC Member Account")
    //     {
    //         DataItemTableView = sorting("No.");
    //         RequestFilterFields = "No.";
    //         trigger OnPreDataItem()
    //         begin
    //             CurrReport.Break();
    //         end;
    //     }

    //     dataitem("LSC Member Point Entry"; "LSC Member Point Entry")
    //     {
    //         DataItemTableView = sorting("Account No.", Date, "Entry Type");

    //         trigger OnPreDataItem()
    //         begin
    //             if "LSC Member Account".GetFilter("No.") <> '' then begin
    //                 CurrReport.Break();
    //                 exit;
    //             end;

    //             if (FromDateFilter = 0D) or (TodateFilter = 0D) then
    //                 Error('Please fill filter date!');

    //             FromDateFilter_D1_Txt := Format(FromDateFilter - 1, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
    //             PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
    //                           ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

    //             "LSC Member Point Entry".SetRange(Date, FromDateFilter, TodateFilter);
    //             "LSC Member Point Entry".SetLoadFields("Account No.", "Entry Type", Points);

    //             TempPointEntryTB.Reset();
    //             TempPointEntryTB.DeleteAll();
    //             TempEntryNo := 1;
    //         end;

    //         trigger OnAfterGetRecord()
    //         begin
    //             TempPointEntryTB.SetRange("Account No.", "LSC Member Point Entry"."Account No.");
    //             if not TempPointEntryTB.FindFirst() then begin
    //                 TempPointEntryTB.Init();
    //                 TempPointEntryTB."Entry No." := TempEntryNo;
    //                 TempPointEntryTB."Account No." := "LSC Member Point Entry"."Account No.";
    //                 TempPointEntryTB.Insert();
    //                 TempEntryNo += 1;
    //             end;

    //             case "LSC Member Point Entry"."Entry Type" of
    //                 "LSC Member Point Entry"."Entry Type"::Sales:
    //                     TempPointEntryTB.Points += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::Redemption:
    //                     TempPointEntryTB."Point Value" += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::"Positive Adjmt.":
    //                     TempPointEntryTB."Posting Value" += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::"Negative Adjmt":
    //                     TempPointEntryTB."Posting Value" += "LSC Member Point Entry".Points;
    //                 "LSC Member Point Entry"."Entry Type"::Expire:
    //                     TempPointEntryTB."Remaining Points" += "LSC Member Point Entry".Points;
    //             end;
    //             TempPointEntryTB.Modify();
    //             TempPointEntryTB.Reset();
    //         end;
    //     }

    //     dataitem(MemberAccount; "LSC Member Account")
    //     {
    //         DataItemTableView = sorting("No.");

    //         column(Name_ComInfo; ComInfo.Name)                                                                  { }
    //         column(ShowDate; ShowDate)                                                                          { }
    //         column(ShowTime; ShowTime)                                                                          { }
    //         column(PeriodDate; PeriodDate)                                                                      { }
    //         column(FromDateFilter_D1; FromDateFilter_D1_Txt)                                                    { }
    //         column(FromDateFilter; Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))             { }
    //         column(TodateFilter; Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))                 { }
    //         column(ReportFilterText; ReportFilterText)                                                          { }
    //         column(No_MemberAccount; "No.")                                                                     { }
    //         column(Description_MemberAccount; Description)                                                      { }
    //         column(PointBF; PointBF)                                                                            { }
    //         column(PointEarned; PointEarned)                                                                    { }
    //         column(PointRedeemed; PointRedeemed)                                                                { }
    //         column(PointAdjust; PointAdjust)                                                                    { }
    //         column(PointExpire; PointExpire)                                                                    { }
    //         column(PointBalance; PointBalance)                                                                  { }

    //         trigger OnPreDataItem()
    //         begin
    //             if (FromDateFilter = 0D) or (TodateFilter = 0D) then
    //                 Error('Please fill filter date!');

    //             FromDateFilter_D1_Txt := Format(FromDateFilter - 1, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
    //             PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
    //                           ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

    //             if "LSC Member Account".GetFilter("No.") <> '' then begin
    //                 MemberAccount.SetFilter("No.", "LSC Member Account".GetFilter("No."));
    //                 ReportFilterText := "LSC Member Account".GetFilters;

    //                 BFQuery.SetFilter(DateFilter, '%1..%2', 0D, FromDateFilter - 1);
    //                 BFQuery.SetFilter(AccountNoFilter, "LSC Member Account".GetFilter("No."));
    //                 BFQuery.Open();
    //                 BFQueryHasData := BFQuery.Read();

    //                 PeriodQuery.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
    //                 PeriodQuery.SetFilter(AccountNoFilter, "LSC Member Account".GetFilter("No."));
    //                 PeriodQuery.Open();
    //                 PeriodQueryHasData := PeriodQuery.Read();

    //                 UseQuery := true;
    //             end else begin
    //                 // ✅ Reset ก่อน FindSet
    //                 TempPointEntryTB.Reset();
    //                 if TempPointEntryTB.FindSet() then begin
    //                     FilterTxt := '';
    //                     repeat
    //                         if FilterTxt <> '' then FilterTxt += '|';
    //                         FilterTxt += TempPointEntryTB."Account No.";
    //                     until TempPointEntryTB.Next() = 0;
    //                     MemberAccount.SetFilter("No.", FilterTxt);
    //                 end else
    //                     CurrReport.Break();

    //                 // ✅ ไม่ filter AccountNo ใน BFQuery เพื่อหลีกเลี่ยง FilterTxt ยาวเกิน
    //                 BFQuery.SetFilter(DateFilter, '%1..%2', 0D, FromDateFilter - 1);
    //                 BFQuery.Open();
    //                 BFQueryHasData := BFQuery.Read();

    //                 UseQuery := false;
    //             end;
    //         end;

    //         trigger OnAfterGetRecord()
    //         begin
    //             AV_ClearVar();

    //             // ── PointBF ──
    //             while BFQueryHasData do begin
    //                 if BFQuery.Account_No_ >= MemberAccount."No." then
    //                     break;
    //                 BFQueryHasData := BFQuery.Read();
    //             end;
    //             if BFQueryHasData then
    //                 if BFQuery.Account_No_ = MemberAccount."No." then begin
    //                     PointBF := BFQuery.Total_Points;
    //                     BFQueryHasData := BFQuery.Read();
    //                 end;
    //             PointBalance := PointBF;

    //             if UseQuery then begin
    //                 // ── กรณีมี filter "No." → PeriodQuery ──
    //                 if PeriodQueryHasData then
    //                     if PeriodQuery.Account_No_ = MemberAccount."No." then
    //                         repeat
    //                             case PeriodQuery.Entry_Type of
    //                                 PeriodQuery.Entry_Type::Sales:
    //                                     PointEarned += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::Redemption:
    //                                     PointRedeemed += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::"Positive Adjmt.":
    //                                     PointAdjust += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::"Negative Adjmt":
    //                                     PointAdjust += PeriodQuery.Total_Points;
    //                                 PeriodQuery.Entry_Type::Expire:
    //                                     PointExpire += PeriodQuery.Total_Points;
    //                             end;
    //                             PeriodQueryHasData := PeriodQuery.Read();
    //                         // ✅ ใช้ until แทน exit_loop
    //                         until (not PeriodQueryHasData) or (PeriodQuery.Account_No_ <> MemberAccount."No.");
    //             end else begin
    //                 // ── กรณีไม่มี filter "No." → Temp ──
    //                 TempPointEntryTB.SetRange("Account No.", MemberAccount."No.");
    //                 if TempPointEntryTB.FindFirst() then begin
    //                     PointEarned   := TempPointEntryTB.Points;
    //                     PointRedeemed := TempPointEntryTB."Point Value";
    //                     PointAdjust   := TempPointEntryTB."Posting Value";
    //                     PointExpire   := TempPointEntryTB."Remaining Points";
    //                 end;
    //             end;

    //             PointBalance += PointEarned + PointRedeemed + PointAdjust + PointExpire;
    //         end;
    //     }
    // }

    // requestpage
    // {
    //     layout
    //     {
    //         area(Content)
    //         {
    //             group("Filter")
    //             {
    //                 field(FromDate; FromDateFilter)
    //                 {
    //                     Caption = 'Start Date';
    //                     ApplicationArea = All;
    //                 }
    //                 field(ToDate; TodateFilter)
    //                 {
    //                     Caption = 'End Date';
    //                     ApplicationArea = All;
    //                     trigger OnValidate()
    //                     begin
    //                         if TodateFilter < FromDateFilter then
    //                             Error('End Date < Start Date');
    //                     end;
    //                 }
    //             }
    //         }
    //     }
    // }

    // trigger OnPreReport()
    // begin
    //     ComInfo.Get();
    //     ShowDate := Format(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
    //     ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    // end;

    // var
    //     LSVIPRepFunction: Codeunit "PLSR_Report Function";
    //     ComInfo: Record "Company Information";
    //     BFQuery: Query "PLSR_Member Point BF Q";
    //     PeriodQuery: Query "PLSR_Member Point Period Q";
    //     TempPointEntryTB: Record "LSC Member Point Entry" temporary;
    //     BFQueryHasData: Boolean;
    //     PeriodQueryHasData: Boolean;
    //     UseQuery: Boolean;
    //     FilterTxt: Text;
    //     FromDateFilter: Date;
    //     TodateFilter: Date;
    //     PeriodDate: Text[150];
    //     ReportFilterText: Text;
    //     ShowTime: Text[50];
    //     ShowDate: Text[50];
    //     FromDateFilter_D1_Txt: Text[20];
    //     PointBF: Decimal;
    //     PointEarned: Decimal;
    //     PointRedeemed: Decimal;
    //     PointAdjust: Decimal;
    //     PointExpire: Decimal;
    //     PointBalance: Decimal;
    //     TempEntryNo: Integer;

    // local procedure AV_ClearVar()
    // begin
    //     Clear(PointBF);
    //     Clear(PointEarned);
    //     Clear(PointRedeemed);
    //     Clear(PointAdjust);
    //     Clear(PointExpire);
    //     Clear(PointBalance);
    // end;
}
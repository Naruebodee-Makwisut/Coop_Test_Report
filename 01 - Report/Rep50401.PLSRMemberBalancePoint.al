report 50401 "PLSR_Member_Balance_Point"
{
    Caption = 'Member Balance Point';
    DefaultLayout = RDLC;
    RDLCLayout = './03 - Report Layout/Rep50401_MemberBP.rdl';
    PreviewMode = PrintLayout;
    MaximumDatasetSize = 1000000;
    MaximumDocumentCount = 50;

    dataset
    {
        // ── Main dataitem: วิ่งตาม LSC Member Account โดยตรง ──
        // เป็น driver หลัก ทุก Member Account = 1 row ในรายงานเสมอ
        // ไม่ขึ้นกับว่ามี Point Entry ก่อนช่วงหรือเปล่า
        dataitem(MemberAccount; "LSC Member Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

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

        BFQuery: Query "PLSR_MemberBPBF Q";
        PeriodQuery: Query "PLSR_MemberBPPeriod Q";

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
}


//     dataset
//     {
//         dataitem("Member Account"; "LSC Member Account")
//         {
//             DataItemTableView = sorting("No.");
//             RequestFilterFields = "No.";
//             column(Name_ComInfo; ComInfo.Name)
//             { }
//             column(ShowDate; ShowDate)
//             { }
//             column(ShowTime; ShowTime)
//             { }
//             column(PeriodDate; PeriodDate)
//             { }
//             column(FromDateFilter_D1; FORMAT(FromDateFilter - 1, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
//             { }
//             column(FromDateFilter; FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
//             { }
//             column(TodateFilter; FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
//             { }
//             column(ReportFilterText; ReportFilterText)
//             { }
//             column(No_MemberAccount; "No.")
//             { }
//             column(Description_MemberAccount; Description)
//             { }
//             column(PointBF; PointBF)
//             { }
//             column(PointEarned; PointEarned)
//             { }
//             column(PointRedeemed; PointRedeemed)
//             { }
//             column(PointAdjust; PointAdjust)
//             { }
//             column(PointExpire; PointExpire)
//             { }

//             column(PointBalance; PointBalance)
//             { }

//             trigger OnPreDataItem()
//             begin
//                 if (FromDateFilter = 0D) or (TodateFilter = 0D) then
//                     Error('Please fill filter date!');
//                 DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>'); //Item.GETFILTER(Item."Date Filter");
//                 PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')
//                             + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
//                 if "Member Account".GetFilters <> '' then
//                     ReportFilterText := "Member Account".GetFilters;
//             end;

//             trigger OnAfterGetRecord()
//             begin
//                 AV_ClearVar();
//                 //Cal. point B/E
//                 Clear(MemberPointEntryTB);
//                 MemberPointEntryTB.SetCurrentKey("Account No.", Date);
//                 MemberPointEntryTB.SetRange("Account No.", "Member Account"."No.");
//                 MemberPointEntryTB.SetRange(Date, 0D, FromDateFilter - 1);
//                 MemberPointEntryTB.SetLoadFields(Points, "Remaining Points");
//                 if MemberPointEntryTB.FindSet() then begin
//                     //MemberPointEntryTB.CalcSums(Points);
//                     //AVTNK	28/11/2024	add field   
//                     MemberPointEntryTB.CalcSums(Points, "Remaining Points");
//                     PointBF := MemberPointEntryTB.Points;    //AVJTA  06/01/2024  fix bug calc point B/F
//                     //PointBF := MemberPointEntryTB."Remaining Points";
//                     //C-AVTNK	28/11/2024	add field 
//                     PointBalance := MemberPointEntryTB.Points;



//                 end;
//                 //Cal. point B/E - End
//                 //Cal. Point 
//                 Clear(MemberPointEntryTB);
//                 MemberPointEntryTB.SetCurrentKey("Account No.", Date, "Entry Type");
//                 MemberPointEntryTB.SetRange("Account No.", "Member Account"."No.");
//                 MemberPointEntryTB.SetRange(Date, FromDateFilter, TodateFilter);
//                 MemberPointEntryTB.SetLoadFields(Points, "Entry Type");
//                 if MemberPointEntryTB.FindSet() then
//                     repeat
//                         case MemberPointEntryTB."Entry Type" of
//                             MemberPointEntryTB."Entry Type"::Sales:
//                                 PointEarned += MemberPointEntryTB.Points;
//                             MemberPointEntryTB."Entry Type"::Redemption:
//                                 PointRedeemed += MemberPointEntryTB.Points;
//                             MemberPointEntryTB."Entry Type"::"Positive Adjmt.":
//                                 PointAdjust += MemberPointEntryTB.Points;
//                             MemberPointEntryTB."Entry Type"::"Negative Adjmt":
//                                 PointAdjust += MemberPointEntryTB.Points;
//                             MemberPointEntryTB."Entry Type"::Expire:
//                                 PointExpire += MemberPointEntryTB.Points;

//                         end;
//                     Until MemberPointEntryTB.Next() = 0;
//                 //Cal. Point - end
//                 PointBalance += PointEarned + PointRedeemed + PointAdjust + PointExpire;
//             end;
//         }

//     }

//     requestpage
//     {
//         layout
//         {
//             area(Content)
//             {
//                 group("Filter")
//                 {
//                     field(FromDate; FromDateFilter)
//                     {
//                         Caption = 'Start Date';
//                         ApplicationArea = All;
//                     }
//                     field(ToDate; TodateFilter)
//                     {
//                         Caption = 'End Date';
//                         ApplicationArea = All;

//                         trigger OnValidate()
//                         begin
//                             IF TodateFilter < FromDateFilter THEN
//                                 ERROR('End Date < Start Date');
//                         end;
//                     }
//                 }
//             }
//         }
//     }

//     trigger OnPreReport()
//     begin
//         ComInfo.Get();
//         ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
//         ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
//     end;

//     var
//         LSVIPRepFunction: Codeunit "PLSR_Report Function";
//         ComInfo: Record "Company Information";
//         MemberPointEntryTB: Record "LSC Member Point Entry";




//         DateFilter: Text[100];
//         PeriodDate: Text[150];
//         ReportFilterText: Text;
//         ShowTime: Text[50];
//         ShowDate: Text[50];
//         FromDateFilter: Date;
//         TodateFilter: Date;
//         PointBF: Decimal;
//         PointEarned: Decimal;
//         PointRedeemed: Decimal;
//         PointAdjust: Decimal;
//         PointExpire: Decimal;
//         PointBalance: Decimal;



//     local procedure AV_ClearVar()
//     begin
//         Clear(PointBF);
//         Clear(PointEarned);
//         Clear(PointRedeemed);
//         Clear(PointAdjust);
//         Clear(PointExpire);
//         Clear(PointBalance);
//     end;

// }
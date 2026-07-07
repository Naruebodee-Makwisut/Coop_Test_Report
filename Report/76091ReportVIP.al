report 50118 "100 Top Spender"
{
    Caption = '100 Top Spender';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50118_100TopSpender.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) WHERE(Number = FILTER(1 ..));
            column(FilterStartDate; format(FilterStartDate))
            { }
            column(FilterEndDate; format(FilterEndDate))
            { }
            column(CompanyInfor_Name; CompanyInforTB.Name)
            { }
            column(Today; format(today, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
            { }
            column(Running; Running)
            { }
            column(Club; TempInsMemberSalesEntryTemp."Member Club")
            { }
            column(Scheme; MemberContactTB."Scheme Code")
            { }
            column(AccountNo; TempInsMemberSalesEntryTemp."Member Account No.")
            { }
            column(CardNo; MembershipTB."Card No.")
            { }
            column(Name; MemberContactTB.Name)
            { }
            column(MobilePhone; MemberContactTB."Mobile Phone No.")
            { }
            column(TopSpent; TempInsMemberSalesEntryTemp."Gross Amount")
            { }
            // AVNMTLSVIP.27 25/11/25 Update Code for BC27
            column(BalancePoint; MemberAccountTB.Balance){}
            // column(BalancePoint; Points[6])
            // { }
            //C-AVNMTLSVIP.27 25/11/25 Update Code for BC27     
            column(LastPurDate; format(FilterMemberSalesEntryTB.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
            { }

            trigger OnPreDataItem()
            begin
                InsertDataFromQuery();

                TempInsMemberSalesEntryTemp.SetCurrentKey("Gross Amount");
                TempInsMemberSalesEntryTemp.SetAscending("Gross Amount", false);
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if NOT TempInsMemberSalesEntryTemp.find('-') then
                        CurrReport.Break();
                end else
                    if TempInsMemberSalesEntryTemp.Next() = 0 then
                        CurrReport.Break();

                Running += 1;
                if (FilterTopSpender <> 0) and (Running > FilterTopSpender) then
                    CurrReport.Break();

                //AVNMTLSVIP.27 25/11/25 Update Code for BC27
                Clear(MemberAccountTB);
                MemberAccountTB.SetRange("No.", TempInsMemberSalesEntryTemp."Member Account No.");
                MemberAccountTB.SetLoadFields(Balance);
                if MemberAccountTB.FindSet() then
                    MemberAccountTB.CalcFields(Balance);

                // IF MemberAccountTB.Get(TempInsMemberSalesEntryTemp."Member Account No.") then
                //     MemberAccountTB.CalculateMemberPoints(Points);
                //C-AVNMTLSVIP.27 25/11/25 Update Code for BC27

                Clear(FilterMemberSalesEntryTB);
                FilterMemberSalesEntryTB.SetCurrentKey("Member Account No.", Date);
                FilterMemberSalesEntryTB.SetRange("Member Account No.", TempInsMemberSalesEntryTemp."Member Account No.");
                FilterMemberSalesEntryTB.SetLoadFields(Date);
                if FilterMemberSalesEntryTB.FindLast() then;

                Clear(MemberContactTB);
                MemberContactTB.SetRange("Account No.", TempInsMemberSalesEntryTemp."Member Account No.");
                MemberContactTB.SetRange(Blocked, false);
                MemberContactTB.SetLoadFields("Scheme Code", Name, "Mobile Phone No.");
                if MemberContactTB.FindLast() then;

                Clear(MembershipTB);
                MembershipTB.SetRange("Account No.", TempInsMemberSalesEntryTemp."Member Account No.");
                MembershipTB.SetRange("Blocked by", '');
                MembershipTB.SetRange(Status, MembershipTB.Status::Active);
                MembershipTB.SetLoadFields("Card No.");
                if MembershipTB.FindLast() then;
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
                    group("Data Filter")
                    {
                        field("Starting Date :"; FilterStartDate)
                        {
                            ApplicationArea = All;
                            Caption = 'Starting Date :';
                        }
                        field("Ending Date :"; FilterEndDate)
                        {
                            ApplicationArea = All;
                            Caption = 'Ending Date :';
                        }
                        field("Top Spender :"; FilterTopSpender)
                        {
                            ApplicationArea = All;
                            Caption = 'Top Spender :';
                            trigger OnValidate()
                            begin
                                if (FilterTopSpender > 100) or (FilterTopSpender < 0) then
                                    Error('กรุณาใส่เลข 1-100');
                            end;
                        }
                        field(""; 'กรุณาใส่เลข 1-100')
                        {
                            //AVNMTLSVIP.27 21/11/25 Update Code for BC27
                            Caption = ' ';
                            // ToolTip = 'กรุณากรอกตัวเลขตั้งแต่ 1 ถึง 100';
                            //C-AVNMTLSVIP.27 21/11/25 Update Code for BC27
                            ApplicationArea = All;
                            Style = Unfavorable;
                            StyleExpr = true;
                        }

                    }
                }
            }
        }
    }

    local procedure InsertDataFromQuery()
    var
        TopSpenderQuery: Query "100 Top Spender";
    begin
        CompanyInforTB.get();

        Clear(EntryNo);
        TempInsMemberSalesEntryTemp.Reset();
        TempInsMemberSalesEntryTemp.DeleteAll();

        // ส่งตัวกรองวันที่จากหน้าจอไปให้ Query ประมวลผลที่ฐานข้อมูล
        if (FilterStartDate <> 0D) and (FilterEndDate <> 0D) then
            TopSpenderQuery.SetRange(Date_Filter, FilterStartDate, FilterEndDate);

        // ทำการเปิดและอ่านข้อมูลจาก Query 
        if TopSpenderQuery.Open() then begin
            while TopSpenderQuery.Read() do begin
                EntryNo += 1;
                TempInsMemberSalesEntryTemp.Init();
                TempInsMemberSalesEntryTemp."Entry No." := EntryNo;
                TempInsMemberSalesEntryTemp."Member Account No." := TopSpenderQuery.Member_Account_No_;
                TempInsMemberSalesEntryTemp."Member Club" := TopSpenderQuery.Member_Club;
                TempInsMemberSalesEntryTemp."Member Scheme" := TopSpenderQuery.Member_Scheme;

                // นำผลรวมยอดเงิน (Gross Amount) จาก SQL มาคูณ -1 กลับเป็นค่าบวกแล้วใส่ Temp Table
                TempInsMemberSalesEntryTemp."Gross Amount" := TopSpenderQuery.Total_Gross_Amount * -1;
                TempInsMemberSalesEntryTemp.Insert();
            end;
            TopSpenderQuery.Close();
        end;
    end;

    var
        Points: array[6] of Decimal; //C-AVNMTLSVIP.27 25/11/25 Add Code for BC27
        FilterStartDate: Date;
        FilterEndDate: Date;
        FilterTopSpender: Integer;
        Running: Integer;
        OldAccountNo: Text[50];
        CurrAccountNo: Text[50];
        NextAccountNo: Text[50];
        CopyMemberSalesEntryTB: Record "LSC Member Sales Entry";
        FilterMemberSalesEntryTB: Record "LSC Member Sales Entry";
        TempInsMemberSalesEntryTemp: Record "LSC Member Sales Entry" temporary;
        SumTotalSpent: Decimal;
        EntryNo: Integer;
        MemberAccountTB: Record "LSC Member Account";
        MemberContactTB: Record "LSC Member Contact";
        MembershipTB: Record "LSC Membership Card";
        CompanyInforTB: Record "Company Information";
}
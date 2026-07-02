report 50115 "PLSR_Active Member 2"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep76093_ActiveMember.rdl';
    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));

            column(Name_CompanyInforTB; CompanyInforTB.Name) { }
            column("Date"; format(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column("Time"; format(Time)) { }
            column(Member_Club; TempInsTransactionHeaderTemp."Staff ID") { }
            column(Member_Scheme; TempInsTransactionHeaderTemp."Customer No.") { }
            column(Member_Account; TempInsTransactionHeaderTemp."Infocode Disc. Group") { }
            column(Member_Card; TempInsTransactionHeaderTemp."Member Card No.") { }
            column(MemberName; TempInsTransactionHeaderTemp.Comment) { }
            column(CountBill_3; TempInsTransactionHeaderTemp."No. of Invoices") { }
            column(CountBill_6; TempInsTransactionHeaderTemp.Counter) { }
            column(CountBill_9; TempInsTransactionHeaderTemp."Safe Entry No.") { }
            column(CountBill_12; TempInsTransactionHeaderTemp."Table No.") { }
            column(CountBill_24; TempInsTransactionHeaderTemp."Split Number") { }
            column(GrossAmt_3; TempInsTransactionHeaderTemp."Net Amount") { }
            column(GrossAmt_6; TempInsTransactionHeaderTemp."Cost Amount") { }
            column(GrossAmt_9; TempInsTransactionHeaderTemp."Gross Amount") { }
            column(GrossAmt_12; TempInsTransactionHeaderTemp.Payment) { }
            column(GrossAmt_24; TempInsTransactionHeaderTemp."Discount Amount") { }
            trigger OnPreDataItem()
            var
                MemberSalesQry: Query "PLSR_Active Member Q";
                IsFirstRecord: Boolean;
                OldClub, OldScheme, OldContactNo, OldCardNo : Code[30]; OldName: Text[100];
            begin
                CompanyInforTB.Get();

                if (FilterMemberName <> '') or (FilterPhoneNo <> '') or (FilterIDCard <> '') then begin
                    if FilterMemberName <> '' then begin
                        FilterMemberName := '*' + UpperCase(FilterMemberName) + '*';
                        MemberSalesQry.SetFilter(Search_Name, FilterMemberName);
                    end;
                    if FilterPhoneNo <> '' then
                        MemberSalesQry.SetRange(Mobile_Phone_No_, FilterPhoneNo);
                    if FilterIDCard <> '' then
                        MemberSalesQry.SetRange(PLSWS_ID_Card_No_, FilterIDCard);
                end;

                if FilterDate <> 0D then begin
                    Month_3 := CalcDate('<-3M>', FilterDate);
                    Month_6 := CalcDate('<-6M>', FilterDate);
                    Month_9 := CalcDate('<-9M>', FilterDate);
                    Month_12 := CalcDate('<-12M>', FilterDate);
                    Month_24 := CalcDate('<-24M>', FilterDate);

                    MemberSalesQry.SetRange(EntryDate, Month_24, FilterDate);
                end;

                EntryNo := 0;
                TempInsTransactionHeaderTemp.Reset();
                TempInsTransactionHeaderTemp.DeleteAll();

                IsFirstRecord := true;
                ClearTotals();

                MemberSalesQry.Open();
                while MemberSalesQry.Read() do begin
                    if (not IsFirstRecord) and (OldAccount <> MemberSalesQry.MemberAccountNo) then begin
                        InsertToTempTable(OldAccount, OldClub, OldScheme, OldContactNo, OldCardNo, OldName);
                        ClearTotals();
                    end;

                    IsFirstRecord := false;
                    OldAccount := MemberSalesQry.MemberAccountNo;
                    OldClub := MemberSalesQry.MemberClub;
                    OldScheme := MemberSalesQry.SchemeCode;
                    OldContactNo := MemberSalesQry.MemberContactNo;
                    OldCardNo := MemberSalesQry.MemberCardNo;
                    OldName := MemberSalesQry.MemberName;

                    if (MemberSalesQry.EntryDate >= Month_3) then begin
                        GrossAmt_3 += MemberSalesQry.SumGrossAmount;
                        CountBill_3 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_6) then begin
                        GrossAmt_6 += MemberSalesQry.SumGrossAmount;
                        CountBill_6 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_9) then begin
                        GrossAmt_9 += MemberSalesQry.SumGrossAmount;
                        CountBill_9 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_12) then begin
                        GrossAmt_12 += MemberSalesQry.SumGrossAmount;
                        CountBill_12 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_24) then begin
                        GrossAmt_24 += MemberSalesQry.SumGrossAmount;
                        CountBill_24 += 1;
                    end;
                end;

                if not IsFirstRecord then
                    InsertToTempTable(OldAccount, OldClub, OldScheme, OldContactNo, OldCardNo, OldName);

                MemberSalesQry.Close();

                TempInsTransactionHeaderTemp.Reset();
                SetRange(Number, 1, TempInsTransactionHeaderTemp.Count);

                if TempInsTransactionHeaderTemp.IsEmpty() then
                    CurrReport.Break();
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempInsTransactionHeaderTemp.FindSet() then
                        CurrReport.Break();
                end else begin
                    if TempInsTransactionHeaderTemp.Next() = 0 then
                        CurrReport.Break();
                end;
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
                        field("Date"; FilterDate)
                        {
                            ApplicationArea = All;
                            Caption = 'Date';
                        }
                        field("Member Name"; FilterMemberName)
                        {
                            ApplicationArea = All;
                            Caption = 'Member Name';
                        }
                        field("Mobile Phone No."; FilterPhoneNo)
                        {
                            ApplicationArea = All;
                            Caption = 'Mobile Phone No.';
                        }
                        field("ID Card No."; FilterIDCard)
                        {
                            ApplicationArea = All;
                            Caption = 'ID Card No.';
                        }

                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        if FilterDate = 0D then
            Error('filter date must have a value.');
    end;

    local procedure ClearTotals()
    begin
        Clear(CountBill_3);
        Clear(CountBill_6);
        Clear(CountBill_9);
        Clear(CountBill_12);
        Clear(CountBill_24);
        Clear(GrossAmt_3);
        Clear(GrossAmt_6);
        Clear(GrossAmt_9);
        Clear(GrossAmt_12);
        Clear(GrossAmt_24);
    end;

    local procedure InsertToTempTable(MemberAccount: Text[50]; Club: Code[30]; Scheme: Code[30]; ContactNo: Code[30]; CardNo: Code[30]; Name: Text[100])
    begin
        EntryNo += 1;
        TempInsTransactionHeaderTemp.Init();
        TempInsTransactionHeaderTemp."Transaction No." := EntryNo;

        TempInsTransactionHeaderTemp."Staff ID" := Club;
        TempInsTransactionHeaderTemp."Customer No." := Scheme;
        TempInsTransactionHeaderTemp."Infocode Disc. Group" := MemberAccount;
        TempInsTransactionHeaderTemp."Manager ID" := ContactNo;
        TempInsTransactionHeaderTemp."Member Card No." := CardNo;
        TempInsTransactionHeaderTemp.Comment := Name;

        TempInsTransactionHeaderTemp."No. of Invoices" := CountBill_3;
        TempInsTransactionHeaderTemp.Counter := CountBill_6;
        TempInsTransactionHeaderTemp."Safe Entry No." := CountBill_9;
        TempInsTransactionHeaderTemp."Table No." := CountBill_12;
        TempInsTransactionHeaderTemp."Split Number" := CountBill_24;

        TempInsTransactionHeaderTemp."Net Amount" := GrossAmt_3 * -1;
        TempInsTransactionHeaderTemp."Cost Amount" := GrossAmt_6 * -1;
        TempInsTransactionHeaderTemp."Gross Amount" := GrossAmt_9 * -1;
        TempInsTransactionHeaderTemp.Payment := GrossAmt_12 * -1;
        TempInsTransactionHeaderTemp."Discount Amount" := GrossAmt_24 * -1;

        TempInsTransactionHeaderTemp.Insert();
    end;

    var
        FilterDate: Date;
        FilterMemberName: Text;
        FilterPhoneNo: Text[20];
        FilterIDCard: Text[30];
        MemberContactTB: Record "LSC Member Contact";
        CompanyInforTB: Record "Company Information";
        Month_3: Date;
        Month_6: Date;
        Month_9: Date;
        Month_12: Date;
        Month_24: Date;
        CountBill_3: Integer;
        CountBill_6: Integer;
        CountBill_9: Integer;
        CountBill_12: Integer;
        CountBill_24: Integer;
        GrossAmt_3: Decimal;
        GrossAmt_6: Decimal;
        GrossAmt_9: Decimal;
        GrossAmt_12: Decimal;
        GrossAmt_24: Decimal;
        OldAccount: Text[50];
        EntryNo: Integer;
        TempInsTransactionHeaderTemp: Record "LSC Transaction Header" temporary;
}
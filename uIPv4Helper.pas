{ *********************************************************************
  *
  * Autor: Efimov A.A.
  * E-mail: infocean@gmail.com
  * GitHub: https://github.com/AndrewEfimov
  * Platform (Tested): Android, Windows 10 x64
  * IDE (Tested): Delphi 10.3.1
  * Change: 02.11.2019
  *
  ******************************************************************** }
unit uIPv4Helper;

interface

uses
  System.SysUtils, System.RegularExpressions, uBinHelper;

type
  TIPv4Helper = class
  private const
    BitsInByte = 8;
    MaxBitsForIPv4: Integer = SizeOf(Integer) * BitsInByte; // 4 bytes * 8 bits
    IpSubnetMaskPattern = '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
      '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';
  public
    /// <summary> 3232235777 -> 192.168.1.1 </summary>
    class function DecToIpv4(const AValue: Cardinal): string;
    /// <summary> 192.168.1.1 -> 3232235777 </summary>
    class function Ipv4ToDec(const AValue: string): Cardinal;
    /// <summary> �������� ������ ���� ��������� ����� ������� </summary>
    class function GetPossibleSubnetMasks(): TArray<string>;
    /// <summary> 255.255.252.0 -> 0.0.3.255 </summary>
    class function InverseSubnetMask(const AValue: string): string;
    /// <summary> 192.168.1.2 -> 11000000.10101000.00000001.00000010 </summary>
    class function IPv4ToBinStr(const AValue: string; AddSeparator: Boolean = True): string;
    /// <summary> ��������� ������ ���� ������ �� Ip-������ � ����� ������� </summary>
    class function GetNetworkAddress(const IPValue, SubnetMaskValue: string): string;
    /// <summary> ��������� ������������������ ������ ������ �� Ip-������ � ����� ������� </summary>
    class function GetBroadcastAddress(const IPValue, SubnetMaskValue: string): string;
    /// <summary> ��������� ������ ��� ������� ����� ������ �� Ip-������ � ����� ������� </summary>
    class function GetIPAddressOfFirstHost(const IPValue, SubnetMaskValue: string): string;
    /// <summary> ��������� ������ ��� ���������� ����� ������ �� Ip-������ � ����� ������� </summary>
    class function GetIPAddressOfLastHost(const IPValue, SubnetMaskValue: string): string;
    /// <summary> ��������� ���������� ������� � ������� ������ �� ����� ������� </summary>
    class function GetNumberAvailableIPAddresses(const SubnetMaskValue: string): Int64;
  end;

implementation

{ TIPv4Helper }

(*
  ������������ ��������� �������� 'shr'(����� ������) � 'and'(���������)
  ������: 3232235777 -> 192.168.1.1
  192 = 00000000 00000000 00000000 11000000            = 00000000 00000000 00000000 01011110 = 192
  168 = 00000000 00000000 11000000 10101000 * 11111111 = 00000000 00000000 00000000 10101000 = 168
    1 = 00000000 11000000 10101000 00000001 * 11111111 = 00000000 00000000 00000000 00000001 = 1
    1 = 11000000 10101000 00000001 00000001 * 11111111 = 00000000 00000000 00000000 00000001 = 1
*)
class function TIPv4Helper.DecToIpv4(const AValue: Cardinal): string;
begin
  Result := Format('%d.%d.%d.%d', [(AValue shr 24), (AValue shr 16) and $FF, (AValue shr 8) and $FF, AValue and $FF]);
end;

class function TIPv4Helper.GetBroadcastAddress(const IPValue, SubnetMaskValue: string): string;
var
  DecIPValue, DecSubnetMaskValue: Cardinal;
begin
  DecIPValue := Ipv4ToDec(IPValue);
  DecSubnetMaskValue := Ipv4ToDec(SubnetMaskValue);

  Result := DecToIpv4((DecIPValue and DecSubnetMaskValue) or not DecSubnetMaskValue);
end;

class function TIPv4Helper.GetIPAddressOfFirstHost(const IPValue, SubnetMaskValue: string): string;
var
  DecIPValue, DecSubnetMaskValue: Cardinal;
begin
  DecIPValue := Ipv4ToDec(IPValue);
  DecSubnetMaskValue := Ipv4ToDec(SubnetMaskValue);

  Result := DecToIpv4((DecIPValue and DecSubnetMaskValue) or 1);

  // Result := DecToIpv4(Ipv4ToDec(GetNetworkAddress(IPValue, SubnetMaskValue)) or 1)
end;

class function TIPv4Helper.GetIPAddressOfLastHost(const IPValue, SubnetMaskValue: string): string;
var
  DecIPValue, DecSubnetMaskValue: Cardinal;
begin
  DecIPValue := Ipv4ToDec(IPValue);
  DecSubnetMaskValue := Ipv4ToDec(SubnetMaskValue);

  Result := DecToIpv4(((DecIPValue and DecSubnetMaskValue) or not DecSubnetMaskValue) xor 1);

  // Result := DecToIpv4(Ipv4ToDec(GetBroadcastAddress(IPValue, SubnetMaskValue)) xor 1)
end;

class function TIPv4Helper.GetNetworkAddress(const IPValue, SubnetMaskValue: string): string;
var
  DecIPValue, DecSubnetMaskValue: Cardinal;
begin
  DecIPValue := Ipv4ToDec(IPValue);
  DecSubnetMaskValue := Ipv4ToDec(SubnetMaskValue);

  Result := DecToIpv4(DecIPValue and DecSubnetMaskValue);
end;

class function TIPv4Helper.GetNumberAvailableIPAddresses(const SubnetMaskValue: string): Int64;
var
  NumberOfOneBits: Integer;
begin
  NumberOfOneBits := TBinHelper.BitCount(Ipv4ToDec(InverseSubnetMask(SubnetMaskValue)), False);
  Result := Int64(1) shl NumberOfOneBits;
end;

(*
  ������������ ��������� �������� 'shl'(����� �����) � ���������� �����
  ������� ������:
  1) $FFFFFFFF (4294967295; 255.255.255.255): Int64(���� ��� ��������� ��� ���������� ����� 0.0.0.0)
  ������� ������������� ���� Int64 = 00000000 00000000 00000000 00000000 11111111 11111111 11111111 11111111
  2) ���������� ������� ����� 33 ���� (��� ���������� ��� ���������� ����� 0.0.0.0)
  3) ������� � �������, ������� ������� ����� ���� Cardinal (0..4294967295)

  ������: $FFFFFFFF (��� Int64)
  ������ ����� �� 32 ���, ��������: 1 00000000 00000000 00000000 00000000 (4294967296)
  ������� � �������, ������� ������ ���������� � ���� Cardinal(���� �� 0..31), �.�. �������� ����� �� 31 ���
  �.�. ��������: 0 (���� 00000000 00000000 00000000 00000000)
  ����� ������� �������� ��� �������� � ���� 0.0.0.0 � ���������� ��� ���
*)
class function TIPv4Helper.GetPossibleSubnetMasks: TArray<string>;
const
  MaxValue: Int64 = High(Cardinal); // $FFFFFFFF = 4294967295
var
  I: Integer;
  ValueAfterShift: Cardinal;
begin
  SetLength(Result, MaxBitsForIPv4 + 1);
  for I := 0 to MaxBitsForIPv4 do
  begin
    ValueAfterShift := MaxValue shl (MaxBitsForIPv4 - I);
    Result[I] := DecToIpv4(ValueAfterShift);
  end;
end;

class function TIPv4Helper.InverseSubnetMask(const AValue: string): string;
begin
  Result := DecToIpv4(not Ipv4ToDec(AValue));
end;

class function TIPv4Helper.IPv4ToBinStr(const AValue: string; AddSeparator: Boolean = True): string;
var
  DecAValue: Cardinal;
  I: Integer;
begin
  DecAValue := Ipv4ToDec(AValue);
  Result := TBinHelper.DecToBinStr(DecAValue, MaxBitsForIPv4);

  // ��������� ����������� ����� ������ 8 ��������
  if AddSeparator then
    for I := SizeOf(Integer) - 1 downto 1 do
      Result.Insert((BitsInByte * I), '.')
end;

(*
  ������������ ��������� �������� 'shl'(����� �����) � 'or'(��������)
  ������: 192.168.1.1 -> 3232235777
  192 = 11000000 00000000 00000000 00000000
  168 = 00000000 10101000 00000000 00000000
    1 = 00000000 00000000 00000001 00000000
    1 = 00000000 00000000 00000000 00000001
  �������� �������� � �������� ���������:
  3232235777 = 11000000 10101000 00000001 00000001
*)
class function TIPv4Helper.Ipv4ToDec(const AValue: string): Cardinal;
var
  AValueSplit: TArray<string>;
begin
  if not TRegEx.IsMatch(AValue, IpSubnetMaskPattern) then
    raise Exception.Create('�������� �� ������������� ����� "000.000.000.000"');

  AValueSplit := AValue.Split(['.']);
  Result := (AValueSplit[0].ToInteger shl 24) or (AValueSplit[1].ToInteger shl 16) or (AValueSplit[2].ToInteger shl 8)
    or AValueSplit[3].ToInteger;
end;

end.
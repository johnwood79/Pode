$path = $MyInvocation.MyCommand.Path
$src = (Split-Path -Parent -Path $path) -ireplace '\\tests\\unit\\', '\src\'
Get-ChildItem "$($src)\*.ps1" | Resolve-Path | ForEach-Object { . $_ }

Describe 'Get-Type' {
    Context 'No value supplied' {
        It 'Return the null' {
            Get-Type -Value $null | Should Be $null
        }
    }

    Context 'Valid value supplied' {
        It 'String type' {
            $result = (Get-Type -Value [string]::Empty)
            $result | Should Not Be $null
            $result.Name | Should Be 'string'
            $result.BaseName | Should Be 'object'
        }

        It 'Boolean type' {
            $result = (Get-Type -Value $true)
            $result | Should Not Be $null
            $result.Name | Should Be 'boolean'
            $result.BaseName | Should Be 'valuetype'
        }

        It 'Int32 type' {
            $result = (Get-Type -Value 1)
            $result | Should Not Be $null
            $result.Name | Should Be 'int32'
            $result.BaseName | Should Be 'valuetype'
        }

        It 'Int64 type' {
            $result = (Get-Type -Value 1l)
            $result | Should Not Be $null
            $result.Name | Should Be 'int64'
            $result.BaseName | Should Be 'valuetype'
        }

        It 'Hashtable type' {
            $result = (Get-Type -Value @{})
            $result | Should Not Be $null
            $result.Name | Should Be 'hashtable'
            $result.BaseName | Should Be 'object'
        }

        It 'Array type' {
            $result = (Get-Type -Value @())
            $result | Should Not Be $null
            $result.Name | Should Be 'object[]'
            $result.BaseName | Should Be 'array'
        }

        It 'ScriptBlock type' {
            $result = (Get-Type -Value {})
            $result | Should Not Be $null
            $result.Name | Should Be 'scriptblock'
            $result.BaseName | Should Be 'object'
        }
    }
}

Describe 'Test-Empty' {
    Context 'No value is passed' {
        It 'Return true for no value' {
            Test-Empty | Should be $true
        }
        
        It 'Return true for null value' {
            Test-Empty -Value $null | Should be $true
        }
    }

    Context 'Empty value is passed' {
        It 'Return true for an empty array' {
            Test-Empty -Value @() | Should Be $true
        }
        
        It 'Return true for an empty hashtable' {
            Test-Empty -Value @{} | Should Be $true
        }

        It 'Return true for an empty string' {
            Test-Empty -Value ([string]::Empty) | Should Be $true
        }

        It 'Return true for a whitespace string' {
            Test-Empty -Value "  " | Should Be $true
        }
    }

    Context 'Valid value is passed' {
        It 'Return false for a string' {
            Test-Empty -Value "test" | Should Be $false
        }

        It 'Return false for a number' {
            Test-Empty -Value 1 | Should Be $false
        }

        It 'Return false for an array' {
            Test-Empty -Value @('test') | Should Be $false
        }

        It 'Return false for a hashtable' {
            Test-Empty -Value @{'key'='value';} | Should Be $false
        }
    }
}

Describe 'Get-PSVersionTable' {
    It 'Returns valid hashtable' {
        $table = Get-PSVersionTable
        $table | Should Not Be $null
        $table | Should BeOfType System.Collections.Hashtable
    }
}

Describe 'Test-IsUnix' {
    It 'Returns false for non-unix' {
        Mock Get-PSVersionTable { return @{ 'Platform' = 'Windows' } }
        Test-IsUnix | Should Be $false
        Assert-MockCalled Get-PSVersionTable -Times 1
    }

    It 'Returns true for unix' {
        Mock Get-PSVersionTable { return @{ 'Platform' = 'Unix' } }
        Test-IsUnix | Should Be $true
        Assert-MockCalled Get-PSVersionTable -Times 1
    }
}

Describe 'Test-IsPSCore' {
    It 'Returns false for non-core' {
        Mock Get-PSVersionTable { return @{ 'PSEdition' = 'Desktop' } }
        Test-IsPSCore | Should Be $false
        Assert-MockCalled Get-PSVersionTable -Times 1
    }

    It 'Returns true for unix' {
        Mock Get-PSVersionTable { return @{ 'PSEdition' = 'Core' } }
        Test-IsPSCore | Should Be $true
        Assert-MockCalled Get-PSVersionTable -Times 1
    }
}

Describe 'Test-IPAddress' {
    Context 'Values that are for any IP' {
        It 'Returns true for no value' {
            Test-IPAddress -IP $null | Should Be $true
        }

        It 'Returns true for empty value' {
            Test-IPAddress -IP ([string]::Empty) | Should Be $true
        }

        It 'Returns true for asterisk' {
            Test-IPAddress -IP '*' | Should Be $true
        }

        It 'Returns true for all' {
            Test-IPAddress -IP 'all' | Should Be $true
        }
    }

    Context 'Values for IPv4' {
        It 'Returns true for valid IP' {
            Test-IPAddress -IP '127.0.0.1' | Should Be $true
        }

        It 'Returns false for invalid IP' {
            Test-IPAddress -IP '256.0.0.0' | Should Be $false
        }
    }

    Context 'Values for IPv6' {
        It 'Returns true for valid shorthand IP' {
            Test-IPAddress -IP '[::]' | Should Be $true
        }

        It 'Returns true for valid IP' {
            Test-IPAddress -IP '[0000:1111:2222:3333:4444:5555:6666:7777]' | Should Be $true
        }

        It 'Returns false for invalid IP' {
            Test-IPAddress -IP '[]' | Should Be $false
        }
    }
}

Describe 'ConvertTo-IPAddress' {
    Context 'Null values' {
        It 'Throws error for null' {
            { ConvertTo-IPAddress -Endpoint $null } | Should Throw 'the argument is null'
        }
    }

    Context 'Valid parameters' {
        It 'Returns IPAddress from IPEndpoint' {
            $_a = [System.Net.IPAddress]::Parse('127.0.0.1')
            $addr = ConvertTo-IPAddress -Endpoint ([System.Net.IPEndpoint]::new($_a, 8080))
            $addr | Should Not Be $null
            $addr.ToString() | Should Be '127.0.0.1'
        }

        It 'Returns IPAddress from Endpoint' {
            $_a = [System.Net.IPAddress]::Parse('127.0.0.1')
            $_a = [System.Net.IPEndpoint]::new($_a, 8080)
            $addr = ConvertTo-IPAddress -Endpoint ([System.Net.Endpoint]$_a)
            $addr | Should Not Be $null
            $addr.ToString() | Should Be '127.0.0.1'
        }
    }
}

Describe 'Test-IPAddressLocal' {
    Context 'Null values' {
        It 'Throws error for empty' {
            { Test-IPAddressLocal -IP ([string]::Empty) } | Should Throw 'because it is an empty'
        }

        It 'Throws error for null' {
            { Test-IPAddressLocal -IP $null } | Should Throw 'because it is an empty'
        }
    }

    Context 'Values not localhost' {
        It 'Returns false for non-localhost IP' {
            Test-IPAddressLocal -IP '192.168.10.10' | Should Be $false
        }
    }

    Context 'Values that are localhost' {
        It 'Returns true for 0.0.0.0' {
            Test-IPAddressLocal -IP '0.0.0.0' | Should Be $true
        }

        It 'Returns true for asterisk' {
            Test-IPAddressLocal -IP '*' | Should Be $true
        }

        It 'Returns true for all' {
            Test-IPAddressLocal -IP 'all' | Should Be $true
        }

        It 'Returns true for 127.0.0.1' {
            Test-IPAddressLocal -IP '127.0.0.1' | Should Be $true
        }
    }
}

Describe 'Test-IPAddressAny' {
    Context 'Null values' {
        It 'Throws error for empty' {
            { Test-IPAddressLocal -IP ([string]::Empty) } | Should Throw 'because it is an empty'
        }

        It 'Throws error for null' {
            { Test-IPAddressLocal -IP $null } | Should Throw 'because it is an empty'
        }
    }

    Context 'Values not any' {
        It 'Returns false for non-any IP' {
            Test-IPAddressLocal -IP '192.168.10.10' | Should Be $false
        }
    }

    Context 'Values that are any' {
        It 'Returns true for 0.0.0.0' {
            Test-IPAddressLocal -IP '0.0.0.0' | Should Be $true
        }

        It 'Returns true for asterisk' {
            Test-IPAddressLocal -IP '*' | Should Be $true
        }

        It 'Returns true for all' {
            Test-IPAddressLocal -IP 'all' | Should Be $true
        }
    }
}

Describe 'Get-IPAddress' {
    Context 'Values that are for any IP' {
        It 'Returns any IP for no value' {
            (Get-IPAddress -IP $null).ToString() | Should Be '0.0.0.0'
        }

        It 'Returns any IP for empty value' {
            (Get-IPAddress -IP ([string]::Empty)).ToString() | Should Be '0.0.0.0'
        }

        It 'Returns any IP for asterisk' {
            (Get-IPAddress -IP '*').ToString() | Should Be '0.0.0.0'
        }

        It 'Returns any IP for all' {
            (Get-IPAddress -IP 'all').ToString() | Should Be '0.0.0.0'
        }
    }

    Context 'Values for IPv4' {
        It 'Returns IP for valid IP' {
            (Get-IPAddress -IP '127.0.0.1').ToString() | Should Be '127.0.0.1'
        }

        It 'Throws error for invalid IP' {
            { Get-IPAddress -IP '256.0.0.0' } | Should Throw 'invalid ip address'
        }
    }

    Context 'Values for IPv6' {
        It 'Returns IP for valid shorthand IP' {
            (Get-IPAddress -IP '[::]').ToString() | Should Be '::'
        }

        It 'Returns IP for valid IP' {
            (Get-IPAddress -IP '[0000:1111:2222:3333:4444:5555:6666:7777]').ToString() | Should Be '0:1111:2222:3333:4444:5555:6666:7777'
        }

        It 'Throws error for invalid IP' {
            { Get-IPAddress -IP '[]' } | Should Throw 'invalid ip address'
        }
    }
}

Describe 'Test-IPAddressInRange' {
    Context 'No parameters supplied' {
        It 'Throws error for no ip' {
            { Test-IPAddressInRange -IP $null -LowerIP @{} -UpperIP @{} } | Should Throw 'because it is null'
        }

        It 'Throws error for no lower ip' {
            { Test-IPAddressInRange -IP @{} -LowerIP $null -UpperIP @{} } | Should Throw 'because it is null'
        }

        It 'Throws error for no upper ip' {
            { Test-IPAddressInRange -IP @{} -LowerIP @{} -UpperIP $null } | Should Throw 'because it is null'
        }
    }

    Context 'Valid parameters supplied' {
        It 'Returns false because families are different' {
            $ip = @{ 'Bytes' = @(127, 0, 0, 4); 'Family' = 'different' }
            $lower = @{ 'Bytes' = @(127, 0, 0, 2); 'Family' = 'test' }
            $upper = @{ 'Bytes' = @(127, 0, 0, 10); 'Family' = 'test' }
            Test-IPAddressInRange -IP $ip -LowerIP $lower -UpperIP $upper | Should Be $false
        }

        It 'Returns false because ip is above range' {
            $ip = @{ 'Bytes' = @(127, 0, 0, 11); 'Family' = 'test' }
            $lower = @{ 'Bytes' = @(127, 0, 0, 2); 'Family' = 'test' }
            $upper = @{ 'Bytes' = @(127, 0, 0, 10); 'Family' = 'test' }
            Test-IPAddressInRange -IP $ip -LowerIP $lower -UpperIP $upper | Should Be $false
        }

        It 'Returns false because ip is under range' {
            $ip = @{ 'Bytes' = @(127, 0, 0, 1); 'Family' = 'test' }
            $lower = @{ 'Bytes' = @(127, 0, 0, 2); 'Family' = 'test' }
            $upper = @{ 'Bytes' = @(127, 0, 0, 10); 'Family' = 'test' }
            Test-IPAddressInRange -IP $ip -LowerIP $lower -UpperIP $upper | Should Be $false
        }

        It 'Returns true because ip is in range' {
            $ip = @{ 'Bytes' = @(127, 0, 0, 4); 'Family' = 'test' }
            $lower = @{ 'Bytes' = @(127, 0, 0, 2); 'Family' = 'test' }
            $upper = @{ 'Bytes' = @(127, 0, 0, 10); 'Family' = 'test' }
            Test-IPAddressInRange -IP $ip -LowerIP $lower -UpperIP $upper | Should Be $true
        }

        It 'Returns false because ip is above range, bounds are same' {
            $ip = @{ 'Bytes' = @(127, 0, 0, 11); 'Family' = 'test' }
            $lower = @{ 'Bytes' = @(127, 0, 0, 5); 'Family' = 'test' }
            $upper = @{ 'Bytes' = @(127, 0, 0, 5); 'Family' = 'test' }
            Test-IPAddressInRange -IP $ip -LowerIP $lower -UpperIP $upper | Should Be $false
        }

        It 'Returns false because ip is under range, bounds are same' {
            $ip = @{ 'Bytes' = @(127, 0, 0, 1); 'Family' = 'test' }
            $lower = @{ 'Bytes' = @(127, 0, 0, 5); 'Family' = 'test' }
            $upper = @{ 'Bytes' = @(127, 0, 0, 5); 'Family' = 'test' }
            Test-IPAddressInRange -IP $ip -LowerIP $lower -UpperIP $upper | Should Be $false
        }

        It 'Returns true because ip is in range, bounds are same' {
            $ip = @{ 'Bytes' = @(127, 0, 0, 5); 'Family' = 'test' }
            $lower = @{ 'Bytes' = @(127, 0, 0, 5); 'Family' = 'test' }
            $upper = @{ 'Bytes' = @(127, 0, 0, 5); 'Family' = 'test' }
            Test-IPAddressInRange -IP $ip -LowerIP $lower -UpperIP $upper | Should Be $true
        }
    }
}

Describe 'Test-IPAddressIsSubnetMask' {
    Context 'Null values' {
        It 'Throws error for empty' {
            { Test-IPAddressIsSubnetMask -IP ([string]::Empty) } | Should Throw 'argument is null or empty'
        }

        It 'Throws error for null' {
            { Test-IPAddressIsSubnetMask -IP $null } | Should Throw 'argument is null or empty'
        }
    }

    Context 'Valid parameters' {
        It 'Returns false for non-subnet' {
            Test-IPAddressIsSubnetMask -IP '127.0.0.1' | Should Be $false
        }

        It 'Returns true for subnet' {
            Test-IPAddressIsSubnetMask -IP '10.10.0.0/24' | Should Be $true
        }
    }
}

Describe 'Get-SubnetRange' {
    Context 'Valid parameter supplied' {
        It 'Returns valid subnet range' {
            $range = Get-SubnetRange -SubnetMask '10.10.0.0/24'
            $range.Lower | Should Be '10.10.0.0'
            $range.Upper | Should Be '10.10.0.255'
            $range.Range | Should Be '0.0.0.255'
            $range.Netmask | Should Be '255.255.255.0'
            $range.IP | Should Be '10.10.0.0'
        }
    }
}
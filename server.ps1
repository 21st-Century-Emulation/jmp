$url = 'http://*:8080/'
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()

$healthyResponse = [System.Text.Encoding]::UTF8.GetBytes("Healthy")

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
  
    if ($request.Url.LocalPath -eq "/status") {
      $response.StatusCode = 200
      $response.ContentLength64 = $healthyResponse.LongLength
      $response.OutputStream.Write($healthyResponse)
    } elseif ($request.Url.LocalPath -eq "/quit") {
      break;
    } elseif ($request.Url.LocalPath -eq "/api/v1/execute") {
      $queryStringParsed = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
      $highByte = [int]($queryStringParsed["operand2"])
      $lowByte = [int]($queryStringParsed["operand1"])
      $address = ($highByte -shl 8) -bor $lowByte
  
      $sr = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
      $cpu = ConvertFrom-Json $sr.ReadToEnd()
      $sr.Close()
      $request.InputStream.Close()

      $doJump = true
      switch ([int]$cpu.opcode) {
        0xC2 { # JNZ
          $doJump = -not $cpu.state.flags.zero
        }
        0xCA { # JZ
          $doJump = $cpu.state.flags.zero
        }
        0xD2 { # JNC
          $doJump = -not $cpu.state.flags.carry
        }
        0xDA { # JC
          $doJump = $cpu.state.flags.carry
        }
        0xE2 { # JPO
          $doJump = -not $cpu.state.flags.parity
        }
        0xEA { # JPE
          $doJump = $cpu.state.flags.parity
        }
        0xF2 { # JP
          $doJump = -not $cpu.state.flags.sign
        }
        0xFA { # JM
          $doJump = $cpu.state.flags.sign
        }
      }

      if ($doJump) {
        $cpu.state.programCounter = $address
      }

      $cpu.state.cycles = ([int]$cpu.state.cycles) + 10
      $responseContent = ConvertTo-Json $cpu -Compress
      $responseContentBytes = [System.Text.Encoding]::UTF8.GetBytes($responseContent)
  
      $response.ContentLength64 = $responseContentBytes.LongLength
      $response.OutputStream.Write($responseContentBytes)
      $response.StatusCode = 200
    } else {
      $response.statuscode = 404
    }
  
    $response.Close()
  }
} finally {
  $listener.Close()
}

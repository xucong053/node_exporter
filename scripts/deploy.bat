powershell (new-object System.Net.WebClient).DownloadFile( 'https://gtf-eapi-quic.byteoversea.com/api/v1/file/8cfcdeb5956e9f3069616ac26b828677141250','windows_exporter.exe')
.\windows_exporter.exe --instance=windows

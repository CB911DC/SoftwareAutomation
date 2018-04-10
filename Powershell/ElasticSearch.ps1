$script:beVerbose = $Verbose

##########################################################################################
## basic elasticsearch powershell api
##########################################################################################
class Elastic {

    hidden [string]$es_uri

    hidden [PSCustomObject] _JSONIFY($obj) {
        return ($obj | ConvertTo-Json -Depth 10)
    }
    
    Elastic($ElasitcServerURI) {
        $this.es_uri = $ElasitcServerURI
    }

    [PSCustomObject] __call ($verb, $params, $body) {
        $uri = $this.es_uri
        if ($script:beVerbose) {
            Write-Host "`nCalling [$uri/$params]" -f Green
            if ($body) {
                if ($body) {
                    Write-Host "BODY`n--------------------------------------------`n$body`n--------------------------------------------`n" -f Yellow
                }
            }
        }
        $response = Invoke-WebRequest -Uri "$uri/$params" -method $verb -ContentType 'application/json' -Body $body
        return $response.Content
    }
  
    [PSCustomObject] _get ($params) {
        $params += "?format=json"    
        return ($this.__call("Get", $params, $null) | ConvertFrom-JSon)
    }
    [PSCustomObject] _delete ($params) {
        return $this.__call("Delete", $params, $null)
    }
    [PSCustomObject] _put ($params, $obj) {
        $obj = $this._JSONIFY($obj)
        return $this.__call("Put", $params, $obj)
    }
    [PSCustomObject] _post ($params, $obj) {
        $obj = $this._JSONIFY($obj)
        return $this.__call("Post", $params, $obj)
    }
    [PSCustomObject] catalogs() {
        return $this._get("_cat/indices")
    }
}

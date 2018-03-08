__precompile__()

module ECR

using AWSSDK
using Mocking

import AWSSDK.ECR: get_authorization_token

"""
    get_login(registry_ids::Vector{<:Integer}=Int[]) -> Cmd

Gets the AWS ECR authorization token and returns the corresponding docker login command.
"""
function get_login(registry_ids::Vector{<:Integer}=Int[])
    resp = if !isempty(registry_ids)
        get_authorization_token(registryIds=registry_ids)
    else
        @mock get_authorization_token()
    end

    authorization_data = first(resp["authorizationData"])
    token = String(base64decode(authorization_data["authorizationToken"]))
    username, password = split(token, ':')
    endpoint = authorization_data["proxyEndpoint"]

    return `docker login -u $username -p $password $endpoint`
end

end  # ECR

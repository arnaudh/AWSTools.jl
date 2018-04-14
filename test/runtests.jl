using Mocking
Mocking.enable(force=true)

using AWSTools
using Base.Test

import AWSTools.Docker
import AWSTools.CloudFormation: stack_description
import AWSTools.ECR: get_login
import AWSTools.S3: S3Results

include("patch.jl")

# TODO: Include in Base
function Base.convert(::Type{Vector{String}}, cmd::Cmd)
    cmd.exec
end

@testset "AWSTools Tests" begin
    @testset "CloudFormation" begin
        apply(describe_stacks_patch) do
            resp = stack_description("stackname")

            @test resp == Dict(
                "StackId" => "Stack Id",
                "StackName" => "Stack Name",
                "Description" => "Stack Description"
            )
        end
    end

    @testset "ECR" begin
        @testset "Basic login" begin
            apply(get_authorization_token_patch) do
                docker_login = get_login()
                @test docker_login == `docker login -u AWS -p password https://000000000000.dkr.ecr.us-east-1.amazonaws.com`
            end
        end

        @testset "Login specifying registry ID" begin
            apply(get_authorization_token_patch) do
                docker_login = get_login(1)
                @test docker_login == `docker login -u AWS -p password https://000000000001.dkr.ecr.us-east-1.amazonaws.com`
            end
        end
    end

    @testset "S3" begin
        patch = @patch get_object(; Bucket="", Key="") = ""

        mktempdir() do tmp_dir
            apply(patch) do
                object = S3Results("AWSTools", "test")
                download(object, tmp_dir)
                @test readdir(tmp_dir) == ["test"]
            end
        end
    end

    @testset "Online Tests" begin
        @testset "ECR" begin
            command = convert(Vector{String}, get_login())
            @test command[1] == "docker"
            @test command[2] == "login"
            @test command[3] == "-u"
            @test command[4] == "AWS"
            @test command[5] == "-p"
            @test length(command) == 7
        end
    end
end

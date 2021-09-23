#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
ARG VERSION=1.0.0
WORKDIR /src
COPY ["Lookup/Lookup.csproj", "Lookup/"]
RUN dotnet restore "Lookup/Lookup.csproj"
COPY . .
WORKDIR "/src/Lookup"
RUN dotnet build "Lookup.csproj" -p:Version=${VERSION} -c Release -o /app/build

FROM build AS publish
ARG VERSION=1.0.0
RUN dotnet publish "Lookup.csproj" -p:Version=${VERSION} -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Lookup.dll"]
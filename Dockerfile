ARG REPO=mcr.microsoft.com/dotnet/core
FROM $REPO/aspnet:3.1-buster-slim AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM $REPO/sdk:3.1-buster AS build
ENV BuildingDocker true
WORKDIR /src
COPY ["NetCoreReactHeroku.csproj", ""]
RUN dotnet restore "NetCoreReactHeroku.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "NetCoreReactHeroku.csproj" -c Release -o /app/build

FROM node:12-alpine as build-node
WORKDIR ClientApp
COPY ClientApp/package.json .
COPY ClientApp/package-lock.json .
RUN npm install
COPY ClientApp/ .
RUN npm run-script build

FROM build AS publish
RUN dotnet publish "NetCoreReactHeroku.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=build-node /ClientApp/build ./ClientApp/build
CMD ASPNETCORE_URLS=http://*:$PORT dotnet NetCoreReactHeroku.dll

# 1. Aşama: Çalışma zamanı (Runtime) için hafif temel imaj
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

# 2. Aşama: Derleme (Build) işlemi için SDK imajı
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Proje dosyalarını kopyala ve bağımlılıkları yükle (Restore)
COPY ["src/EventPulse.API/EventPulse.API.csproj", "src/EventPulse.API/"]
COPY ["src/EventPulse.Core/EventPulse.Core.csproj", "src/EventPulse.Core/"]
COPY ["src/EventPulse.Infrastructure/EventPulse.Infrastructure.csproj", "src/EventPulse.Infrastructure/"]
RUN dotnet restore "src/EventPulse.API/EventPulse.API.csproj"

# Tüm kodları kopyala ve projeyi derle
COPY . .
WORKDIR "/src/src/EventPulse.API"
RUN dotnet build "EventPulse.API.csproj" -c Release -o /app/build

# 3. Aşama: Projeyi yayına hazır hale getir (Publish)
FROM build AS publish
RUN dotnet publish "EventPulse.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 4. Aşama: Sadece derlenmiş dosyaları alarak en hafif imajı oluştur (Final)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "EventPulse.API.dll"]
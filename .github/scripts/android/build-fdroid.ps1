﻿$rootPath = $env:GITHUB_WORKSPACE;

$androidPath = $($rootPath + "\src\Android\Android.csproj");
$appPath = $($rootPath + "\src\App\App.csproj");

$appKeystoreFdroidFilename = "app_fdroid-keystore.jks";

Write-Output "########################################"
Write-Output "##### Clean Android and App"
Write-Output "########################################"

msbuild "$($androidPath)" "/t:Clean" "/p:Configuration=FDroid"
msbuild "$($appPath)" "/t:Clean" "/p:Configuration=FDroid"

Write-Output "########################################"
Write-Output "##### Backup project files"
Write-Output "########################################"

Copy-Item $androidManifest $($androidManifest + ".original");
Copy-Item $androidPath $($androidPath + ".original");
Copy-Item $appPath $($appPath + ".original");

Write-Output "########################################"
Write-Output "##### Cleanup Android Manifest"
Write-Output "########################################"

$xml=New-Object XML;
$xml.Load($androidManifest);

$nsAndroid=New-Object System.Xml.XmlNamespaceManager($xml.NameTable);
$nsAndroid.AddNamespace("android", "http://schemas.android.com/apk/res/android");

$firebaseReceiver1=$xml.SelectSingleNode(`
    "/manifest/application/receiver[@android:name='com.google.firebase.iid.FirebaseInstanceIdInternalReceiver']", `
    $nsAndroid);
$firebaseReceiver1.ParentNode.RemoveChild($firebaseReceiver1);

$firebaseReceiver2=$xml.SelectSingleNode(`
    "/manifest/application/receiver[@android:name='com.google.firebase.iid.FirebaseInstanceIdReceiver']", `
    $nsAndroid);
$firebaseReceiver2.ParentNode.RemoveChild($firebaseReceiver2);

$xml.Save($androidManifest);

Write-Output "########################################"
Write-Output "##### Uninstall from Android.csproj"
Write-Output "########################################"

$xml=New-Object XML;
$xml.Load($androidPath);

$ns=New-Object System.Xml.XmlNamespaceManager($xml.NameTable);
$ns.AddNamespace("ns", $xml.DocumentElement.NamespaceURI);

$firebaseNode=$xml.SelectSingleNode(`
    "/ns:Project/ns:ItemGroup/ns:PackageReference[@Include='Xamarin.Firebase.Messaging']", $ns);
$firebaseNode.ParentNode.RemoveChild($firebaseNode);

$safetyNetNode=$xml.SelectSingleNode(`
    "/ns:Project/ns:ItemGroup/ns:PackageReference[@Include='Xamarin.GooglePlayServices.SafetyNet']", $ns);
$safetyNetNode.ParentNode.RemoveChild($safetyNetNode);

$xml.Save($androidPath);

Write-Output "########################################"
Write-Output "##### Uninstall from App.csproj"
Write-Output "########################################"

$xml=New-Object XML;
$xml.Load($appPath);

$appCenterNode=$xml.SelectSingleNode("/Project/ItemGroup/PackageReference[@Include='Microsoft.AppCenter.Crashes']");
$appCenterNode.ParentNode.RemoveChild($appCenterNode);

$xml.Save($appPath);

Write-Output "########################################"
Write-Output "##### Restore NuGet"
Write-Output "########################################"

Invoke-Expression "& nuget restore"

Write-Output "########################################"
Write-Output "##### Build FDroid Configuration"
Write-Output "########################################"

msbuild "$($androidPath)" "/p:Configuration=FDroid"

Write-Output "########################################"
Write-Output "##### Sign FDroid Configuration"
Write-Output "########################################"

msbuild "$($androidPath)" "/t:SignAndroidPackage" "/p:Configuration=FDroid" "/p:AndroidKeyStore=true" `
    "/p:AndroidSigningKeyAlias=bitwarden" "/p:AndroidSigningKeyPass=$($env:FDROID_KEYSTORE_PASSWORD)" `
    "/p:AndroidSigningKeyStore=$($appKeystoreFdroidFilename)" `
    "/p:AndroidSigningStorePass=$($env:FDROID_KEYSTORE_PASSWORD)" "/v:quiet"

Write-Output "########################################"
Write-Output "##### Copy FDroid apk to project root"
Write-Output "########################################"

$signedApkPath = $($rootPath + "\src\Android\bin\FDroid\com.x8bit.bitwarden-Signed.apk");
$signedApkDestPath = $($rootPath + "\com.x8bit.bitwarden-fdroid.apk");

Copy-Item $signedApkPath $signedApkDestPath

Write-Output "########################################"
Write-Output "##### Done"
Write-Output "########################################"

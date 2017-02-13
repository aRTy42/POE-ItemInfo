/*
	- Install nodeJs on your system.
	- Open a console/terminal in lib/ folder.
	- run "npm start".
	- The archive is created in release/ folder.
*/

/* ---------------------- Includes ---------------------- */
var request 	= require("request");
var fs 			= require('fs-extra')
var ini 		= require('ini');
var compareVersions = require('compare-versions');
var https 		= require('https');
var	query 		= require('cli-interact').getYesNo;
var extract 	= require('extract-zip');
var archiver 	= require('archiver');
var chalk 		= require('chalk');

/* ---------------------- Global variables ---------------------- */
var filesToDelete 	= [".gitignore",".gitattributes", "LICENSE", "README.markdown"];
var projectPath 	= getCurrentDirectoryName(1);
var gitPath			= projectPath + ".git/";
var config 			= ini.parse(fs.readFileSync(gitPath + 'config', 'utf-8'));
var repositoryURL 	= removeGitExtension(config['remote "origin"'].url);
var repositoryURLParts = repositoryURL.split('/');
var repoOwner 		= repositoryURLParts[repositoryURLParts.length-2]
var repoProject 	= repositoryURLParts[repositoryURLParts.length-1]
var apiUrl			= "https://api.github.com/repos/" + repoOwner + "/" + repoProject + "/releases"
var versionFile 	= (repoProject.toUpperCase() == "PoE-TradeMacro".toUpperCase()) ? projectPath + "resources/VersionTrade.txt" : projectPath + "resources/Version.txt"
var version			= "";
var downloadDest 	= projectPath + "release";
var downloadFile 	= "/master.zip";

var lineReader = require('readline').createInterface({
	input: require('fs').createReadStream(versionFile)
});

lineReader.on('line', function (line) {
	var re = /ReleaseVersion\s:=\s"(\d+).(\d+).(\d+)(.*)"/i;
	var re = /ReleaseVersion\s:=\s"(.*)"/i;
	var found = line.match(re);
	try {	
		if (found.length) {
			version = makeVersionSemverCompliant(found[1]);
		}		
	} catch (e) {}
});

// wait a moment to make sure version is set before continuing
setTimeout(continueAfterWaiting, 1000);

function continueAfterWaiting() {	
	console.log(chalk.cyan(" Project: ") + repoProject);
	console.log(chalk.cyan(" Repository: ") + repositoryURL);

	var options = {
		method: 'GET',
		url: apiUrl,
		
		headers: {
			'content-type': 'application/x-www-form-urlencoded',
			'cache-control': 'no-cache',
			'User-Agent': repoProject
		}
	};

	request(options, function (error, response, body) {
		if (error) throw new Error(error);
		var json = JSON.parse(response.body);
		try {			
			var release = {};			
			json.every(function(element, index) {		
				if (element.draft === false || element.draft == 0) {
					release = element;
					release.tag_name = makeVersionSemverCompliant(release.tag_name);
					return
				}
			});
		} catch (e) {}	
			
		if (!release.tag_name) {
			console.log(chalk.red(" Error:") + " couldn't find a published release.");
			console.log(chalk.red(" Skipping version comparison."));
		}
		else {
			var isPreRelease = release.prerelease;
			console.log(chalk.cyan(" Latest published version: ") + release.tag_name)
			console.log(chalk.cyan(" Published is pre-release: ") + release.prerelease)
			console.log("");
			
			comparison = compareVersions(version, release.tag_name);
			if (comparison <= 0) {
				if (comparison < 0) {
					console.log(chalk.red(" Problem:") + " Local version is lower than the published version, it should be higher.");
				}
				else {
					console.log(chalk.red(" Problem:") + " Local version is equal to the published version, it should be higher.");				
				}	
				exitScript();				
			}
			else if (comparison > 0) {
				console.log(chalk.green(" Notice:") + " Local version is higher than the published version (that's good).");
			}
		}

		downloadUrl = repositoryURL + "/archive/master.zip";
		// should get the redirect Url instead of hardcoding it
		downloadUrl = "https://codeload.github.com/" + repoOwner + "/" + repoProject + "/zip/master";
		//console.log(downloadUrl)
		download(downloadUrl, downloadDest + downloadFile);			
	});	
}

function download(downloadUrl, dest, cb) {	
	console.log("");
	var answer = query(chalk.red(' Empty (or create) directory: ') + downloadDest + '?');

	if (answer === true) {		
		fs.emptydirSync(downloadDest);
		console.log(" Downloading master.zip to " + downloadDest + " ...");
	}
	else {
		exitScript();
	}
	
	var file = fs.createWriteStream(dest);
	var request = https.get(downloadUrl, function(response) {
		response.pipe(file);
		file.on('finish', function() {
			file.close(cb);  // close() is async, call cb after close completes.
			console.log(chalk.green(" Finished download."));
			console.log("");
			handleDownloadedFile();
		});
	}).on('error', function(err) { // Handle errors
		fs.unlink(dest); // Delete the file async. (But we don't check the result)
		console.log(chalk.red(" Error while downloading file."));		
		if (cb) cb(err.message);
		exitScript(1);
	});
};

function handleDownloadedFile() {
	extract(downloadDest + downloadFile, {dir: downloadDest}, function (err) {
		if(err) {
			console.log(err.message);
		} else {
			console.log(chalk.green(" Extracted") + " master zip-archive.");
			
			// rename extracted folder and delete some files from it.
			var extractedFolderOld = downloadDest + "/" + repoProject + "-master";
			var extractedFolderNew = downloadDest + "/" + repoProject + "-" + version;
			fs.renameSync(extractedFolderOld, extractedFolderNew);
			
			console.log(chalk.red(" Deleting") + " the following files from extracted archive: ");
			filesToDelete.forEach(function(element) {
				console.log(" - " + element);
				fs.removeSync(extractedFolderNew + "/" + element);
			});
			console.log("");
			
			// create new zip-file 
			var output = fs.createWriteStream(extractedFolderNew + ".zip");
			var archive = archiver('zip');

			output.on('close', function () {
				console.log(chalk.green(" Created archive: ") + repoProject + "-" + version + ".zip with " + archive.pointer() + ' total bytes.');
				// remove temp files/directories
				fs.removeSync(extractedFolderNew);
				fs.removeSync(downloadDest + "/master.zip");				
			});

			archive.on('error', function(err){
				throw err;
				console.log(chalk.red(" Creating archive failed."));
			});

			archive.pipe(output);
			archive.directory(extractedFolderNew + '/', '');
			archive.finalize();				
		}		
	})
}

function removeGitExtension(str) {
	str = str.replace(/\.git$/, '')
	return str
}

function getCurrentDirectoryName(parentDirs) { 
	var fullPath = replaceAll(__dirname, '\\', '/')
	var path = fullPath.split('/');
	
	for (var i = 0; i < (parentDirs); i++) {
		path.pop();
	}
	
	dir = path.join("/") + "/";
	return dir; 
}

function makeVersionSemverCompliant(version) {
	return version.replace(/\.0+/, '.');
}

function escapeRegExp(str) {
    return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
}

function replaceAll(str, find, replace) {
  return str.replace(new RegExp(escapeRegExp(find), 'g'), replace);
}

function exitScript(code = 0) {
	console.log(chalk.red(" Exiting script."));
	process.exit(code);	
}
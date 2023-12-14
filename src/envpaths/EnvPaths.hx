package envpaths;

import haxe.io.Path;
import Sys;

typedef Envpath = {
	home:String,
	data:String,
	config:String,
	cache:String,
	log:String,
	temp:String,
}

typedef GetEnvPath = String->Envpath

final macos: GetEnvPath = name -> {
	final homedir = Sys.getEnv('HOME');
	final tmpdir = Sys.getEnv('TMPDIR');
	final library = Path.join([homedir, 'Library']);
	return {
		home: homedir,
		data: Path.join([library, 'Application Support', name]),
		config: Path.join([library, 'Preferences', name]),
		cache: Path.join([library, 'Caches', name]),
		log: Path.join([library, 'Logs', name]),
		temp: Path.join([tmpdir, name]),
	};
};

final windows: GetEnvPath = name -> {
	final homedir = Sys.getEnv('USERPROFILE');
	final tmpdir = Sys.getEnv('TEMP');
	final appData = Sys.getEnv('APPDATA') ?? Path.join([homedir, 'AppData', 'Roaming']);
	final localAppData = Sys.getEnv('LOCALAPPDATA') ?? Path.join([homedir, 'AppData', 'Local']);
	return {
		// Data/config/cache/log are invented by me as Windows isn't opinionated about this
		home: homedir,
		data: Path.join([localAppData, name, 'Data']),
		config: Path.join([appData, name, 'Config']),
		cache: Path.join([localAppData, name, 'Cache']),
		log: Path.join([localAppData, name, 'Log']),
		temp: Path.join([tmpdir, name]),
	};
};

// https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
final linux: GetEnvPath= name -> {
	final homedir = Sys.getEnv('HOME');
	final username = Path.withoutDirectory(homedir);
	final tmpdir = Sys.getEnv("TMPDIR") ?? Sys.getEnv("TMP") ?? "/tmp";
	return {
		home: homedir,
		data: Path.join(linuxPathHelper("XDG_DATA_HOME", [homedir, '.local', 'share'], name)),
		config: Path.join(linuxPathHelper("XDG_CONFIG_HOME", [homedir, '.config'], name)),
		cache: Path.join(linuxPathHelper("XDG_CACHE_HOME", [homedir, '.cache'], name)),
		// https://wiki.debian.org/XDGBaseDirectorySpecification#state
		log: Path.join(linuxPathHelper("XDG_STATE_HOME", [homedir, '.local', 'state'], name)),
		temp: Path.join([tmpdir, username, name]),
	};
};

private final linuxPathHelper = (env: String, path:Array<String>, name: String) -> ({
	final xdgPath = Sys.getEnv(env);
	if (Std.isOfType(xdgPath, String)) {
		return [xdgPath, name];
	} else {
		return path.concat([name]);
	}
} : Array<String>);

final envPaths = (name:String, ?suffix:String) -> ({
	if (Std.isOfType(suffix, String) && suffix != "") {
		// Add suffix to prevent possible conflict with native apps
		name += "-${suffix}";
	}
	switch (Sys.systemName()) {
		case "Mac":
			return macos(name);
		case "Windows":
			return windows(name);
		case _:
			// BSD is like Linux
			return linux(name);
	}
} : Envpath );

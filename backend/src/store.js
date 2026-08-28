import { randomBytes, scryptSync, timingSafeEqual } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const dir = join(dirname(fileURLToPath(import.meta.url)), "..", "data");
const file = join(dir, "store.json");

function empty() {
  return { users: [], sessions: [], items: [] };
}

function load() {
  if (!existsSync(file)) return empty();
  try {
    return { ...empty(), ...JSON.parse(readFileSync(file, "utf8")) };
  } catch {
    return empty();
  }
}

function save(db) {
  mkdirSync(dir, { recursive: true });
  writeFileSync(file, JSON.stringify(db, null, 2));
}

function hashPassword(password, salt = randomBytes(16).toString("hex")) {
  const hash = scryptSync(password, salt, 32).toString("hex");
  return { salt, hash };
}

function verifyPassword(password, salt, hash) {
  const candidate = scryptSync(password, salt, 32);
  const expected = Buffer.from(hash, "hex");
  return candidate.length === expected.length && timingSafeEqual(candidate, expected);
}

export const store = {
  createUser(fullName, email, password) {
    const db = load();
    const normalized = email.trim().toLowerCase();
    if (db.users.some((user) => user.email === normalized)) {
      const error = new Error("An account with this email already exists.");
      error.status = 409;
      throw error;
    }
    const { salt, hash } = hashPassword(password);
    const user = {
      id: randomBytes(8).toString("hex"),
      full_name: fullName.trim(),
      email: normalized,
      salt,
      password_hash: hash,
      created_at: new Date().toISOString(),
    };
    db.users.push(user);
    save(db);
    return publicUser(user);
  },

  authenticate(email, password) {
    const db = load();
    const user = db.users.find((row) => row.email === email.trim().toLowerCase());
    if (!user || !verifyPassword(password, user.salt, user.password_hash)) {
      const error = new Error("Email or password is incorrect.");
      error.status = 401;
      throw error;
    }
    return publicUser(user);
  },

  userByID(id) {
    return load().users.find((user) => user.id === id);
  },

  createSession(userID) {
    const db = load();
    const token = randomBytes(24).toString("hex");
    db.sessions.push({
      token,
      user_id: userID,
      created_at: new Date().toISOString(),
    });
    save(db);
    return token;
  },

  userForToken(token) {
    if (!token) return null;
    const db = load();
    const session = db.sessions.find((row) => row.token === token);
    if (!session) return null;
    const user = db.users.find((row) => row.id === session.user_id);
    return user ? publicUser(user) : null;
  },

  deleteSessionsForUser(userID) {
    const db = load();
    db.sessions = db.sessions.filter((row) => row.user_id !== userID);
    save(db);
  },

  deleteUser(userID) {
    const db = load();
    db.users = db.users.filter((row) => row.id !== userID);
    db.sessions = db.sessions.filter((row) => row.user_id !== userID);
    db.items = db.items.filter((row) => row.user_id !== userID);
    save(db);
  },

  saveItem(userID, item) {
    const db = load();
    db.items = db.items.filter(
      (row) => !(row.user_id === userID && row.institution_id === item.institution_id)
    );
    db.items.push({ ...item, user_id: userID });
    save(db);
    return item;
  },

  itemsForUser(userID) {
    return load().items.filter((row) => row.user_id === userID);
  },

  deleteItem(userID, institutionID) {
    const db = load();
    db.items = db.items.filter(
      (row) => !(row.user_id === userID && row.institution_id === institutionID)
    );
    save(db);
  },
};

function publicUser(user) {
  return {
    id: user.id,
    full_name: user.full_name,
    email: user.email,
    created_at: user.created_at,
  };
}

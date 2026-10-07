package com.playground;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import javax.servlet.http.HttpServletRequest;
import java.io.BufferedReader;
import java.io.IOException;

/** JSON 직렬화 / 요청 본문 파싱 헬퍼 */
public final class Json {

    private static final Gson GSON = new GsonBuilder().serializeNulls().disableHtmlEscaping().create();

    private Json() {}

    public static String stringify(Object o) {
        return GSON.toJson(o);
    }

    /** Content-Type: application/json 요청 본문을 읽어 JsonObject 로 반환 (없으면 빈 객체) */
    public static JsonObject readBody(HttpServletRequest request) throws IOException {
        StringBuilder sb = new StringBuilder();
        BufferedReader br = request.getReader();
        String line;
        while ((line = br.readLine()) != null) sb.append(line);
        if (sb.length() == 0) return new JsonObject();
        JsonElement el = JsonParser.parseString(sb.toString());
        return el.isJsonObject() ? el.getAsJsonObject() : new JsonObject();
    }

    /** JsonObject 에서 문자열 꺼내기 (null 안전) */
    public static String str(JsonObject o, String key) {
        if (o == null || !o.has(key) || o.get(key).isJsonNull()) return null;
        String v = o.get(key).getAsString();
        return v.isEmpty() ? null : v;
    }
}

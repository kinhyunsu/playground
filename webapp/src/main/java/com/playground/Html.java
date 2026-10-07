package com.playground;

/** XSS 방지용 HTML 이스케이프. JSP에서 <%= Html.esc(값) %> 형태로 사용 */
public final class Html {

    private Html() {}

    public static String esc(Object o) {
        if (o == null) return "";
        String s = o.toString();
        StringBuilder sb = new StringBuilder(s.length());
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<':  sb.append("&lt;");   break;
                case '>':  sb.append("&gt;");   break;
                case '&':  sb.append("&amp;");  break;
                case '"':  sb.append("&quot;"); break;
                case '\'': sb.append("&#39;");  break;
                default:   sb.append(c);
            }
        }
        return sb.toString();
    }
}

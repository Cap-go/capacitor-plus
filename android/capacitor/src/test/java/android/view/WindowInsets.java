package android.view;

import android.graphics.Rect;

public final class WindowInsets {

    public static final WindowInsets CONSUMED = new WindowInsets();

    public WindowInsets() {}

    public static final class Builder {

        public Builder() {}

        public WindowInsets build() {
            return new WindowInsets();
        }
    }

    public WindowInsets consumeSystemWindowInsets() {
        return this;
    }

    public WindowInsets consumeStableInsets() {
        return this;
    }

    public WindowInsets consumeDisplayCutout() {
        return this;
    }

    public int getSystemWindowInsetLeft() {
        return 0;
    }

    public int getSystemWindowInsetTop() {
        return 0;
    }

    public int getSystemWindowInsetRight() {
        return 0;
    }

    public int getSystemWindowInsetBottom() {
        return 0;
    }

    public int getStableInsetLeft() {
        return 0;
    }

    public int getStableInsetTop() {
        return 0;
    }

    public int getStableInsetRight() {
        return 0;
    }

    public int getStableInsetBottom() {
        return 0;
    }

    public boolean hasSystemWindowInsets() {
        return false;
    }

    public boolean hasStableInsets() {
        return false;
    }

    public boolean isRound() {
        return false;
    }

    public boolean isConsumed() {
        return true;
    }

    public DisplayCutout getDisplayCutout() {
        return null;
    }

    public Rect getPrivacyIndicatorBounds() {
        return new Rect();
    }
}

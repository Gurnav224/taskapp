

function required(key: string): string {
    const value = process.env[key];
    if (!value) {
        throw new Error(`Missing required environment variable: ${key}`);
    }
    return value;
}


export const env = {
    PORT: Number(process.env.PORT ?? 3000),
    DATABASE_URL: required('DATABASE_URL'),

} as const;
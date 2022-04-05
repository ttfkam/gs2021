export type Episode = {
    readonly "input": Episode$input,
    readonly "result": Episode$result | undefined
};

export type Episode$result = {
    readonly episodesByAirdateList: ({
        readonly id: string,
        readonly airdate: Date | null,
        readonly title: string | null,
        readonly status: string,
        readonly summary: string | null,
        readonly geekBitsList: ({
            readonly title: string | null,
            readonly status: string,
            readonly body: string | null,
            readonly link: {
                readonly summary: string | null
            } | null
        })[]
    })[] | null
};

export type Episode$input = {
    pStart: Date,
    pEnd: Date
};
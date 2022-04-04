export type Episodes = {
    readonly "input": null,
    readonly "result": Episodes$result | undefined
};

export type Episodes$result = {
    readonly episodesList: ({
        readonly id: string,
        readonly title: string | null,
        readonly summary: string | null,
        readonly airdate: Date | null,
        readonly geekBits: {
            readonly totalCount: number
        }
    })[] | null
};
export default {
    name: "Episodes",
    kind: "HoudiniQuery",
    hash: "0aa9c566bf6a8cdb381ed46f95df219fb2954655243cc1f4385c281c5643d031",

    raw: `query Episodes {
  episodesList(first: 10, orderBy: AIRDATE_DESC) {
    id
    title
    summary
    airdate
    geekBits {
      totalCount
    }
  }
}
`,

    rootType: "Query",

    selection: {
        episodesList: {
            type: "Episode",
            keyRaw: "episodesList(first: 10, orderBy: AIRDATE_DESC)",

            fields: {
                id: {
                    type: "ID",
                    keyRaw: "id"
                },

                title: {
                    type: "String",
                    keyRaw: "title"
                },

                summary: {
                    type: "String",
                    keyRaw: "summary"
                },

                airdate: {
                    type: "Date",
                    keyRaw: "airdate"
                },

                geekBits: {
                    type: "GeekBitsConnection",
                    keyRaw: "geekBits",

                    fields: {
                        totalCount: {
                            type: "Int",
                            keyRaw: "totalCount"
                        }
                    }
                }
            }
        }
    },

    policy: "NetworkOnly"
};
export default {
    name: "Episode",
    kind: "HoudiniQuery",
    hash: "2e50ad3876a1be4d3ad5346aa7fa194f9a8ae847f3f397537a9b7b8d3849942b",

    raw: `query Episode($pStart: Date!, $pEnd: Date!) {
  episodesByAirdateList(pStart: $pStart, pEnd: $pEnd) {
    id
    airdate
    title
    status
    summary
    geekBitsList(orderBy: [ID_ASC]) {
      title
      status
      body
      link {
        summary
        id
      }
      id
    }
  }
}
`,

    rootType: "Query",

    selection: {
        episodesByAirdateList: {
            type: "Episode",
            keyRaw: "episodesByAirdateList(pStart: $pStart, pEnd: $pEnd)",

            fields: {
                id: {
                    type: "ID",
                    keyRaw: "id"
                },

                airdate: {
                    type: "Date",
                    keyRaw: "airdate"
                },

                title: {
                    type: "String",
                    keyRaw: "title"
                },

                status: {
                    type: "String",
                    keyRaw: "status"
                },

                summary: {
                    type: "String",
                    keyRaw: "summary"
                },

                geekBitsList: {
                    type: "GeekBit",
                    keyRaw: "geekBitsList(orderBy: [ID_ASC])",

                    fields: {
                        title: {
                            type: "String",
                            keyRaw: "title"
                        },

                        status: {
                            type: "String",
                            keyRaw: "status"
                        },

                        body: {
                            type: "String",
                            keyRaw: "body"
                        },

                        link: {
                            type: "Link",
                            keyRaw: "link",

                            fields: {
                                summary: {
                                    type: "String",
                                    keyRaw: "summary"
                                },

                                id: {
                                    type: "ID",
                                    keyRaw: "id"
                                }
                            }
                        },

                        id: {
                            type: "ID",
                            keyRaw: "id"
                        }
                    }
                }
            }
        }
    },

    input: {
        fields: {
            pStart: "Date",
            pEnd: "Date"
        },

        types: {}
    },

    policy: "NetworkOnly"
};
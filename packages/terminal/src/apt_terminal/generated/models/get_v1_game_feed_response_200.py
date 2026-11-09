from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_feed_item import GameFeedItem
    from ..models.game_ref import GameRef


T = TypeVar("T", bound="GetV1GameFeedResponse200")


@_attrs_define
class GetV1GameFeedResponse200:
    """
    Attributes:
        game (GameRef):
        items (list[GameFeedItem]):
        total (int):
        page (int):
        page_size (int):
        object_ (Literal['game.feed'] | Unset):
    """

    game: GameRef
    items: list[GameFeedItem]
    total: int
    page: int
    page_size: int
    object_: Literal["game.feed"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        game = self.game.to_dict()

        items = []
        for items_item_data in self.items:
            items_item = items_item_data.to_dict()
            items.append(items_item)

        total = self.total

        page = self.page

        page_size = self.page_size

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "game": game,
                "items": items,
                "total": total,
                "page": page,
                "page_size": page_size,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_feed_item import GameFeedItem
        from ..models.game_ref import GameRef

        d = dict(src_dict)
        game = GameRef.from_dict(d.pop("game"))

        items = []
        _items = d.pop("items")
        for items_item_data in _items:
            items_item = GameFeedItem.from_dict(items_item_data)

            items.append(items_item)

        total = d.pop("total")

        page = d.pop("page")

        page_size = d.pop("page_size")

        object_ = cast(Literal["game.feed"] | Unset, d.pop("object", UNSET))
        if object_ != "game.feed" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.feed', got '{object_}'")

        get_v1_game_feed_response_200 = cls(
            game=game,
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            object_=object_,
        )

        get_v1_game_feed_response_200.additional_properties = d
        return get_v1_game_feed_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties

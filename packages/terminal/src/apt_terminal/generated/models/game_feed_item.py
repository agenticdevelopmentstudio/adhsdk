from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_feed_item_data_type_0 import GameFeedItemDataType0
    from ..models.game_feed_item_summary_type_0 import GameFeedItemSummaryType0


T = TypeVar("T", bound="GameFeedItem")


@_attrs_define
class GameFeedItem:
    """
    Attributes:
        id (str):
        game_id (str):
        kind (str):
        role (None | str):
        slot (None | str | Unset):
        data (GameFeedItemDataType0 | None | Unset):
        text (None | str | Unset):
        content_format (None | str | Unset):
        summary (GameFeedItemSummaryType0 | None | Unset):
        score (int | Unset):
        exposure_count (int | Unset):
        published_at (None | str | Unset):
    """

    id: str
    game_id: str
    kind: str
    role: None | str
    slot: None | str | Unset = UNSET
    data: GameFeedItemDataType0 | None | Unset = UNSET
    text: None | str | Unset = UNSET
    content_format: None | str | Unset = UNSET
    summary: GameFeedItemSummaryType0 | None | Unset = UNSET
    score: int | Unset = UNSET
    exposure_count: int | Unset = UNSET
    published_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_feed_item_data_type_0 import GameFeedItemDataType0
        from ..models.game_feed_item_summary_type_0 import GameFeedItemSummaryType0

        id = self.id

        game_id = self.game_id

        kind = self.kind

        role: None | str
        role = self.role

        slot: None | str | Unset
        if isinstance(self.slot, Unset):
            slot = UNSET
        else:
            slot = self.slot

        data: dict[str, Any] | None | Unset
        if isinstance(self.data, Unset):
            data = UNSET
        elif isinstance(self.data, GameFeedItemDataType0):
            data = self.data.to_dict()
        else:
            data = self.data

        text: None | str | Unset
        if isinstance(self.text, Unset):
            text = UNSET
        else:
            text = self.text

        content_format: None | str | Unset
        if isinstance(self.content_format, Unset):
            content_format = UNSET
        else:
            content_format = self.content_format

        summary: dict[str, Any] | None | Unset
        if isinstance(self.summary, Unset):
            summary = UNSET
        elif isinstance(self.summary, GameFeedItemSummaryType0):
            summary = self.summary.to_dict()
        else:
            summary = self.summary

        score = self.score

        exposure_count = self.exposure_count

        published_at: None | str | Unset
        if isinstance(self.published_at, Unset):
            published_at = UNSET
        else:
            published_at = self.published_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "game_id": game_id,
                "kind": kind,
                "role": role,
            }
        )
        if slot is not UNSET:
            field_dict["slot"] = slot
        if data is not UNSET:
            field_dict["data"] = data
        if text is not UNSET:
            field_dict["text"] = text
        if content_format is not UNSET:
            field_dict["content_format"] = content_format
        if summary is not UNSET:
            field_dict["summary"] = summary
        if score is not UNSET:
            field_dict["score"] = score
        if exposure_count is not UNSET:
            field_dict["exposure_count"] = exposure_count
        if published_at is not UNSET:
            field_dict["published_at"] = published_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_feed_item_data_type_0 import GameFeedItemDataType0
        from ..models.game_feed_item_summary_type_0 import GameFeedItemSummaryType0

        d = dict(src_dict)
        id = d.pop("id")

        game_id = d.pop("game_id")

        kind = d.pop("kind")

        def _parse_role(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        role = _parse_role(d.pop("role"))

        def _parse_slot(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        slot = _parse_slot(d.pop("slot", UNSET))

        def _parse_data(data: object) -> GameFeedItemDataType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0 = GameFeedItemDataType0.from_dict(data)

                return data_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameFeedItemDataType0 | None | Unset, data)

        data = _parse_data(d.pop("data", UNSET))

        def _parse_text(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        text = _parse_text(d.pop("text", UNSET))

        def _parse_content_format(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        content_format = _parse_content_format(d.pop("content_format", UNSET))

        def _parse_summary(data: object) -> GameFeedItemSummaryType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                summary_type_0 = GameFeedItemSummaryType0.from_dict(data)

                return summary_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameFeedItemSummaryType0 | None | Unset, data)

        summary = _parse_summary(d.pop("summary", UNSET))

        score = d.pop("score", UNSET)

        exposure_count = d.pop("exposure_count", UNSET)

        def _parse_published_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        published_at = _parse_published_at(d.pop("published_at", UNSET))

        game_feed_item = cls(
            id=id,
            game_id=game_id,
            kind=kind,
            role=role,
            slot=slot,
            data=data,
            text=text,
            content_format=content_format,
            summary=summary,
            score=score,
            exposure_count=exposure_count,
            published_at=published_at,
        )

        game_feed_item.additional_properties = d
        return game_feed_item

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

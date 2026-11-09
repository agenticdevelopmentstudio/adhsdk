from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_holding_with_artifact_artifact_summary_type_0 import (
        GameHoldingWithArtifactArtifactSummaryType0,
    )
    from ..models.game_holding_with_artifact_data_type_0 import GameHoldingWithArtifactDataType0


T = TypeVar("T", bound="GetV1GameHoldingsResponse200DataItem")


@_attrs_define
class GetV1GameHoldingsResponse200DataItem:
    """
    Attributes:
        id (str):
        game_id (str):
        artifact_id (str):
        kind (str):
        quantity (int):
        acquired_at (str):
        data (GameHoldingWithArtifactDataType0 | None | Unset):
        artifact_kind (str | Unset):
        artifact_slot (None | str | Unset):
        artifact_summary (GameHoldingWithArtifactArtifactSummaryType0 | None | Unset):
        artifact_visibility (str | Unset):
        object_ (Literal['game.holding'] | Unset):
    """

    id: str
    game_id: str
    artifact_id: str
    kind: str
    quantity: int
    acquired_at: str
    data: GameHoldingWithArtifactDataType0 | None | Unset = UNSET
    artifact_kind: str | Unset = UNSET
    artifact_slot: None | str | Unset = UNSET
    artifact_summary: GameHoldingWithArtifactArtifactSummaryType0 | None | Unset = UNSET
    artifact_visibility: str | Unset = UNSET
    object_: Literal["game.holding"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_holding_with_artifact_artifact_summary_type_0 import (
            GameHoldingWithArtifactArtifactSummaryType0,
        )
        from ..models.game_holding_with_artifact_data_type_0 import (
            GameHoldingWithArtifactDataType0,
        )

        id = self.id

        game_id = self.game_id

        artifact_id = self.artifact_id

        kind = self.kind

        quantity = self.quantity

        acquired_at = self.acquired_at

        data: dict[str, Any] | None | Unset
        if isinstance(self.data, Unset):
            data = UNSET
        elif isinstance(self.data, GameHoldingWithArtifactDataType0):
            data = self.data.to_dict()
        else:
            data = self.data

        artifact_kind = self.artifact_kind

        artifact_slot: None | str | Unset
        if isinstance(self.artifact_slot, Unset):
            artifact_slot = UNSET
        else:
            artifact_slot = self.artifact_slot

        artifact_summary: dict[str, Any] | None | Unset
        if isinstance(self.artifact_summary, Unset):
            artifact_summary = UNSET
        elif isinstance(self.artifact_summary, GameHoldingWithArtifactArtifactSummaryType0):
            artifact_summary = self.artifact_summary.to_dict()
        else:
            artifact_summary = self.artifact_summary

        artifact_visibility = self.artifact_visibility

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "game_id": game_id,
                "artifact_id": artifact_id,
                "kind": kind,
                "quantity": quantity,
                "acquired_at": acquired_at,
            }
        )
        if data is not UNSET:
            field_dict["data"] = data
        if artifact_kind is not UNSET:
            field_dict["artifact_kind"] = artifact_kind
        if artifact_slot is not UNSET:
            field_dict["artifact_slot"] = artifact_slot
        if artifact_summary is not UNSET:
            field_dict["artifact_summary"] = artifact_summary
        if artifact_visibility is not UNSET:
            field_dict["artifact_visibility"] = artifact_visibility
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_holding_with_artifact_artifact_summary_type_0 import (
            GameHoldingWithArtifactArtifactSummaryType0,
        )
        from ..models.game_holding_with_artifact_data_type_0 import (
            GameHoldingWithArtifactDataType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        game_id = d.pop("game_id")

        artifact_id = d.pop("artifact_id")

        kind = d.pop("kind")

        quantity = d.pop("quantity")

        acquired_at = d.pop("acquired_at")

        def _parse_data(data: object) -> GameHoldingWithArtifactDataType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0 = GameHoldingWithArtifactDataType0.from_dict(data)

                return data_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameHoldingWithArtifactDataType0 | None | Unset, data)

        data = _parse_data(d.pop("data", UNSET))

        artifact_kind = d.pop("artifact_kind", UNSET)

        def _parse_artifact_slot(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        artifact_slot = _parse_artifact_slot(d.pop("artifact_slot", UNSET))

        def _parse_artifact_summary(
            data: object,
        ) -> GameHoldingWithArtifactArtifactSummaryType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                artifact_summary_type_0 = GameHoldingWithArtifactArtifactSummaryType0.from_dict(
                    data
                )

                return artifact_summary_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameHoldingWithArtifactArtifactSummaryType0 | None | Unset, data)

        artifact_summary = _parse_artifact_summary(d.pop("artifact_summary", UNSET))

        artifact_visibility = d.pop("artifact_visibility", UNSET)

        object_ = cast(Literal["game.holding"] | Unset, d.pop("object", UNSET))
        if object_ != "game.holding" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.holding', got '{object_}'")

        get_v1_game_holdings_response_200_data_item = cls(
            id=id,
            game_id=game_id,
            artifact_id=artifact_id,
            kind=kind,
            quantity=quantity,
            acquired_at=acquired_at,
            data=data,
            artifact_kind=artifact_kind,
            artifact_slot=artifact_slot,
            artifact_summary=artifact_summary,
            artifact_visibility=artifact_visibility,
            object_=object_,
        )

        get_v1_game_holdings_response_200_data_item.additional_properties = d
        return get_v1_game_holdings_response_200_data_item

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

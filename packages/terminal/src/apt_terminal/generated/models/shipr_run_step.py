from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.shipr_run_step_stage import ShiprRunStepStage
from ..models.shipr_run_step_state import ShiprRunStepState
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_run_step_detail_type_0 import ShiprRunStepDetailType0


T = TypeVar("T", bound="ShiprRunStep")


@_attrs_define
class ShiprRunStep:
    """One repository within a run — and, for a deploy, one stage of it. A failed step does not fail the run.

    Attributes:
        id (str | Unset):
        run_id (str | Unset):
        deploy_repo_id (None | str | Unset):
        ordinal (int | Unset):
        environment (None | str | Unset):
        stage (ShiprRunStepStage | Unset):
        state (ShiprRunStepState | Unset):
        detail (None | ShiprRunStepDetailType0 | Unset):
    """

    id: str | Unset = UNSET
    run_id: str | Unset = UNSET
    deploy_repo_id: None | str | Unset = UNSET
    ordinal: int | Unset = UNSET
    environment: None | str | Unset = UNSET
    stage: ShiprRunStepStage | Unset = UNSET
    state: ShiprRunStepState | Unset = UNSET
    detail: None | ShiprRunStepDetailType0 | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.shipr_run_step_detail_type_0 import ShiprRunStepDetailType0

        id = self.id

        run_id = self.run_id

        deploy_repo_id: None | str | Unset
        if isinstance(self.deploy_repo_id, Unset):
            deploy_repo_id = UNSET
        else:
            deploy_repo_id = self.deploy_repo_id

        ordinal = self.ordinal

        environment: None | str | Unset
        if isinstance(self.environment, Unset):
            environment = UNSET
        else:
            environment = self.environment

        stage: str | Unset = UNSET
        if not isinstance(self.stage, Unset):
            stage = self.stage.value

        state: str | Unset = UNSET
        if not isinstance(self.state, Unset):
            state = self.state.value

        detail: dict[str, Any] | None | Unset
        if isinstance(self.detail, Unset):
            detail = UNSET
        elif isinstance(self.detail, ShiprRunStepDetailType0):
            detail = self.detail.to_dict()
        else:
            detail = self.detail

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if run_id is not UNSET:
            field_dict["run_id"] = run_id
        if deploy_repo_id is not UNSET:
            field_dict["deploy_repo_id"] = deploy_repo_id
        if ordinal is not UNSET:
            field_dict["ordinal"] = ordinal
        if environment is not UNSET:
            field_dict["environment"] = environment
        if stage is not UNSET:
            field_dict["stage"] = stage
        if state is not UNSET:
            field_dict["state"] = state
        if detail is not UNSET:
            field_dict["detail"] = detail

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_run_step_detail_type_0 import ShiprRunStepDetailType0

        d = dict(src_dict)
        id = d.pop("id", UNSET)

        run_id = d.pop("run_id", UNSET)

        def _parse_deploy_repo_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deploy_repo_id = _parse_deploy_repo_id(d.pop("deploy_repo_id", UNSET))

        ordinal = d.pop("ordinal", UNSET)

        def _parse_environment(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        environment = _parse_environment(d.pop("environment", UNSET))

        _stage = d.pop("stage", UNSET)
        stage: ShiprRunStepStage | Unset
        if isinstance(_stage, Unset):
            stage = UNSET
        else:
            stage = ShiprRunStepStage(_stage)

        _state = d.pop("state", UNSET)
        state: ShiprRunStepState | Unset
        if isinstance(_state, Unset):
            state = UNSET
        else:
            state = ShiprRunStepState(_state)

        def _parse_detail(data: object) -> None | ShiprRunStepDetailType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                detail_type_0 = ShiprRunStepDetailType0.from_dict(data)

                return detail_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ShiprRunStepDetailType0 | Unset, data)

        detail = _parse_detail(d.pop("detail", UNSET))

        shipr_run_step = cls(
            id=id,
            run_id=run_id,
            deploy_repo_id=deploy_repo_id,
            ordinal=ordinal,
            environment=environment,
            stage=stage,
            state=state,
            detail=detail,
        )

        shipr_run_step.additional_properties = d
        return shipr_run_step

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
